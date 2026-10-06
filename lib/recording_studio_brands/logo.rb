# frozen_string_literal: true

module RecordingStudioBrands
  module Logo
    NAME = "logo"

    def self.recording_for(brand_recording)
      recordings_for([brand_recording])[brand_recording.id]
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
