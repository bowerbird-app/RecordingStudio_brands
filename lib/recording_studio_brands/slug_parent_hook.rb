# frozen_string_literal: true

module RecordingStudioBrands
  # Derives Brand slug parent scope inside RecordingStudio.record! before save.
  module SlugParentHook
    module_function

    def install!
      return unless defined?(RecordingStudio)
      return if @installed

      RecordingStudio.configuration.hooks.before_record(&method(:assign_slug_parent))
      @installed = true
    end

    def assign_slug_parent(payload)
      recordable = payload[:recordable]
      return unless recordable.class.name == BRAND_TYPE

      apply_slug_parent(recordable, payload)
    end

    def apply_slug_parent(recordable, payload)
      parent = payload[:parent_recording] || payload[:recording]&.parent_recording
      recordable.parent_recording_id_for_slug ||= parent&.id
      recordable.slug_uniqueness_except_recording_id ||= payload[:recording]&.id
    end
  end
end
