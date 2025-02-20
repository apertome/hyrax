# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Saves a given work from a change_set, returning a `Dry::Monads::Result`
      # (`Success`|`Failure`).
      #
      # If the save is successful, publishes an `object.metadata.updated` event
      # for the affected resource.
      #
      # @see https://dry-rb.org/gems/dry-monads/1.0/result/
      class Save
        include Dry::Monads[:result]

        ##
        # @params [#save] persister
        def initialize(persister: Hyrax.persister)
          @persister = persister
        end

        ##
        # @param [Hyrax::ChangeSet] change_set
        # @param [::User, nil] user
        #
        # @return [Dry::Monads::Result] `Success(work)` if the change_set is
        #   applied and the resource is saved;
        #   `Failure([#to_s, change_set.resource])`, otherwise.
        def call(change_set, user: nil)
          begin
            unsaved = change_set.sync
            saved = @persister.save(resource: unsaved)
          rescue StandardError => err
            return Failure(["Failed save on #{change_set}\n\t#{err.message}", change_set.resource])
          end

          # if we have a permission manager, it's acting as a local cache of another resource.
          # we want to resync changes that we had in progress so we can persist them later.
          saved.permission_manager.acl.permissions = unsaved.permission_manager.acl.permissions if
            unsaved.respond_to?(:permission_manager)

          user ||= ::User.find_by_user_key(saved.depositor)

          publish_changes(resource: saved, user: user, new: unsaved.new_record)
          Success(saved)
        end

        private

        def publish_changes(resource:, user:, new: false)
          if resource.collection?
            Hyrax.publisher.publish('collection.metadata.updated', collection: resource, user: user)
          else
            Hyrax.publisher.publish('object.deposited', object: resource, user: user) if new
            Hyrax.publisher.publish('object.metadata.updated', object: resource, user: user)
          end
        end
      end
    end
  end
end
