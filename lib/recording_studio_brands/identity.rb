# frozen_string_literal: true

module RecordingStudioBrands
  # Catalogue-style finders for current Brand rows (the recordable currently
  # pointed at by a Brand recording). Seeds and Identity-style callers use these
  # instead of scanning historical revise snapshots.
  module Identity
    module_function

    # Returns the current Brand recordable, or nil.
    def find_brand(slug: nil, name: nil, website_url: nil, parent_recording: nil)
      find_brand_recording(
        slug:,
        name:,
        website_url:,
        parent_recording:
      )&.recordable
    end

    # Returns the Brand recording whose current recordable matches, or nil.
    def find_brand_recording(slug: nil, name: nil, website_url: nil, parent_recording: nil)
      scope = Brand.current
      scope = scope.under_parent(parent_recording) if parent_recording

      if slug.present?
        scope = scope.where(slug: slug.to_s.strip)
      elsif name.present?
        scope = scope.where("LOWER(recording_studio_brands.name) = ?", name.to_s.strip.downcase)
      elsif website_url.present?
        scope = scope.where(website_url: Url.normalize(website_url))
      else
        return
      end

      recording_id = scope.limit(1).pick("recording_studio_recordings.id")
      return if recording_id.blank?

      RecordingStudio::Recording.find_by(id: recording_id, recordable_type: BRAND_TYPE)
    end
  end
end
