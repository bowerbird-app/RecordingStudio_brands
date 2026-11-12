# frozen_string_literal: true

module RecordingStudioBrands
  module Api
    class Create < RecordingStudioApi::Services::ResourceOperations::Create
      def call
        cached = cached_idempotent_response
        return cached if cached

        parent_recording = parent_recording_for_create
        authorize_access!(parent_recording, role: :edit)
        result = created_result(record_brand!(parent_recording))
        store_idempotent_response(result)
        result
      rescue RecordingStudio::InvalidParent => e
        raise invalid_parent_input_error(e.message)
      end

      private

      def record_brand!(parent_recording)
        parent_recording.record(
          Brand,
          parent_recording: parent_recording,
          actor: access_grant.actor || api_client
        ) do |brand|
          brand.parent_recording_id_for_slug = parent_recording.id
          brand.assign_attributes(resource_attributes)
        end
      end

      def created_result(created_recording)
        {
          json: serialize_recording(created_recording, context: relationship_context_for([created_recording])),
          status: :created
        }
      end
    end
  end
end
