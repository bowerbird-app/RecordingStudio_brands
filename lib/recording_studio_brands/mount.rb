# frozen_string_literal: true

module RecordingStudioBrands
  # Mount.for is the only constructor of One and Many, so no caller can build a
  # One for a parent type that allows many.
  module Mount
    module BrandRecordings
      # Includes trashed rows, so a later restore cannot leave two brands under
      # a one mount.
      def brand_recordings
        RecordingStudio::Recording.unscoped
                                  .where(parent_recording_id: parent_recording.id, recordable_type: BRAND_TYPE)
                                  .order(:created_at, :id)
      end
    end
    private_constant :BrandRecordings

    One = Data.define(:parent_recording) do
      include BrandRecordings

      private_class_method :new, :[]

      # Raises rather than pick one when a host switched the parent type from
      # many to one after several brands existed.
      def brand_recording
        first_two = brand_recordings.limit(2).to_a
        raise MountConflict, parent_recording if first_two.size > 1

        first_two.first
      end

      def full?
        brand_recordings.exists?
      end
    end

    # A many mount has no brand_recording, because "the brand" of a list is
    # undefined.
    Many = Data.define(:parent_recording) do
      include BrandRecordings

      private_class_method :new, :[]

      def full?
        false
      end
    end

    KINDS = { one: One, many: Many }.freeze
    private_constant :KINDS

    # Capabilities::Brand.to calls this when the host model loads, and Mount.for
    # calls it again on every read, because core stores capability options
    # without validating them.
    def self.kind_for(allows)
      KINDS.fetch(allows) do
        raise ArgumentError, "Brand mounts need allows: :one or allows: :many, got #{allows.inspect}"
      end
    end

    def self.for(parent_recording)
      return unless RecordingStudio.parent_allowed?(child_type: BRAND_TYPE, parent_recording:)

      options = RecordingStudio.capability_options(:brand, for: parent_recording.recordable_type)
      kind_for(options&.fetch(:allows, nil)).send(:new, parent_recording:)
    end
  end

  # Subclasses core's InvalidParent, so code that rescues placement errors
  # catches a full one mount too.
  class BrandLimitReached < RecordingStudio::InvalidParent
    def initialize(parent_recording)
      label = RecordingStudio.recordable_type_label(parent_recording.recordable_type)
      super("#{label} allows one brand and already has one. Revise that brand instead.")
    end
  end

  class MountConflict < StandardError
    def initialize(parent_recording)
      label = RecordingStudio.recordable_type_label(parent_recording.recordable_type)
      super("#{label} allows one brand but has several. Remove the extra brands before reading the brand.")
    end
  end
end
