require 'wings/hydra/pcdm/models/concerns/object_valkyrie_behavior'

module Wings
  module Works
    module WorkValkyrieBehavior
      extend ActiveSupport::Concern

      included do
        include Wings::Pcdm::ObjectValkyrieBehavior
      end

      # @return [Boolean] whether this instance is a Hydra::Works Collection.
      def collection?
        false
      end

      # @return [Boolean] whether this instance is a Hydra::Works Generic Work.
      def work?
        true
      end

      # @return [Boolean] whether this instance is a Hydra::Works::FileSet.
      def file_set?
        false
      end

      # TODO: Add translated methods
    end
  end
end
