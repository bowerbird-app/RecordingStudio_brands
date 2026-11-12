# frozen_string_literal: true

module RecordingStudioBrands
  module Api
    class Update < RecordingStudioApi::Services::ResourceOperations::Update
      def call
        reject_parent_id_input!
        brand_recording = brand_recording_for_update
        authorize_access!(brand_recording, role: :edit)
        revised = revise_brand!(brand_recording)
        { json: serialize_recording(revised, context: relationship_context_for([revised])) }
      end

      private

      def revise_brand!(brand_recording)
        attributes = resource_attributes.slice(*mutable_attribute_keys)
        return brand_recording if attributes.empty?

        parent_recording = brand_recording.parent_recording
        parent_recording.revise(brand_recording, actor: access_grant.actor || api_client) do |brand|
          brand.parent_recording_id_for_slug = parent_recording.id
          brand.slug_uniqueness_except_recording_id = brand_recording.id
          brand.assign_attributes(attributes)
        end
      end

      def brand_recording_for_update
        brand_recording = recording || scoped_recordings.find_by(id: context.id)
        if brand_recording.nil? || brand_recording.recordable_type != recordable_type
          raise RecordingStudioApi::NotFoundError, "Resource was not found in this API scope"
        end

        brand_recording
      end
    end
  end
end
