# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Reindexes resources when their metadata is updated.
    #
    # @note This listener makes no attempt to avoid reindexing when no metadata
    #   has actually changed, or when real metadata changes won't impact the
    #   indexed data. We trust that published metadata update events represent
    #   actual changes to object metadata, and that the indexing adapter
    #   optimizes reasonably for actual index document contents.
    class MetadataIndexListener
      ##
      # Re-index the resource.
      #
      # Called when 'collection.metadata.updated' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_collection_metadata_updated(event)
        return unless resource? event[:collection]
        Hyrax.index_adapter.save(resource: event[:collection])
      end

      ##
      # Re-index the resource.
      #
      # Called when 'object.metadata.updated' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_metadata_updated(event)
        return unless resource? event[:object]
        Hyrax.index_adapter.save(resource: event[:object])
      end

      ##
      # Remove the resource from the index.
      #
      # Called when 'object.deleted' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_deleted(event)
        return unless resource?(event.payload[:object])
        Hyrax.index_adapter.delete(resource: event[:object])
      end

      private

      def resource?(resource)
        return true if resource.is_a? Valkyrie::Resource
        log_non_resource(resource)
        false
      end

      def log_non_resource(resource)
        generic_type = resource_generic_type(resource)
        Hyrax.logger.info("Skipping #{generic_type} reindex because the " \
                          "#{generic_type} #{resource} was not a Valkyrie::Resource.")
      end

      def resource_generic_type(resource)
        resource.try(:collection?) ? 'collection' : 'object'
      end
    end
  end
end
