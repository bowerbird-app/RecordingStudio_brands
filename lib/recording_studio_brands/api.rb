# frozen_string_literal: true

module RecordingStudioBrands
  # Registers Brand on Recording Studio API when that gem is loaded.
  # This gem does not depend on it. Hosts that skip the API gem keep the UI only.
  # MCP reads the same registration; this gem does not talk to MCP itself.
  module Api
    RECORDABLE_TYPE = RecordingStudioBrands::BRAND_TYPE
    OPERATIONS = %i[index show create update].freeze
    SERIALIZER = lambda { |brand, **|
      RecordingStudioBrands::Api.output_keys.index_with { |name| brand.public_send(name) }
    }.freeze

    class << self
      def register!
        return unless recording_studio_api_available?

        require "recording_studio_brands/api/index"
        require "recording_studio_brands/api/create"
        require "recording_studio_brands/api/update"

        register_type!
        register_handlers!
        true
      end

      def recording_studio_api_available?
        defined?(RecordingStudioApi) &&
          RecordingStudioApi.respond_to?(:register_recordable_type_api) &&
          RecordingStudioApi.respond_to?(:register_resource_handler)
      end

      def output_keys
        writable_attributes + %i[active metadata]
      end

      def writable_attributes
        %i[name tagline description website_url email phone slug]
      end

      private

      def register_type!
        return if RecordingStudioApi.recordable_registration_for(RECORDABLE_TYPE)

        RecordingStudioApi.register_recordable_type_api(
          RECORDABLE_TYPE,
          operations: OPERATIONS,
          serializer: SERIALIZER,
          output_keys: output_keys,
          writable_attributes: writable_attributes,
          capability_actions: []
        )
      end

      def register_handlers!
        register_handler(:index, Index)
        register_handler(:create, Create)
        register_handler(:update, Update)
      end

      def register_handler(action, handler)
        return if RecordingStudioApi.resource_handler(RECORDABLE_TYPE, action)

        RecordingStudioApi.register_resource_handler(RECORDABLE_TYPE, action, handler: handler)
      end
    end
  end
end
