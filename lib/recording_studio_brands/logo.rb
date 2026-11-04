# frozen_string_literal: true

module RecordingStudioBrands
  module Logo
    NAME = "logo"

    def self.recording_for(brand_recording)
      recordings_for([brand_recording])[brand_recording.id]
    end

    # Attachable 0.22 only accepts blobs signed for purpose :attachable_upload
    # and bound to the parent recording and actor.
    def self.upload_blob!(io:, filename:, content_type:, recording:, actor:)
      ActiveStorage::Blob.create_and_upload!(
        io:,
        filename:,
        content_type:,
        identify: false,
        metadata: RecordingStudioAttachable::DirectUpload.metadata_for(recording:, actor:)
      )
    end

    def self.signed_blob_id_for(blob)
      RecordingStudioAttachable::DirectUpload.sign(blob)
    end

    # Two uploads that race can leave two logo attachments. Readers take the
    # newest, and the next upload replaces that one, so the slot converges.
    def self.recordings_for(brand_recordings)
      RecordingStudio::Recording
        .where(
          parent_recording_id: brand_recordings.map(&:id),
          recordable_type: RecordingStudioAttachable::Attachment.name,
          recordable_id: RecordingStudioAttachable::Attachment.images.where(name: NAME).select(:id),
          trashed_at: nil
        )
        .order(created_at: :desc, id: :desc)
        .each_with_object({}) { |logo, by_brand| by_brand[logo.parent_recording_id] ||= logo }
    end
  end
end
