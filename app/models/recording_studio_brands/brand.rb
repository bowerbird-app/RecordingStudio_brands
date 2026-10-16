# frozen_string_literal: true

module RecordingStudioBrands
  # Names no allowed_parent_types. Parent types opt in through
  # RecordingStudio::Capabilities::Brand, so the gem never names host models.
  #
  # Every revise saves a new Brand row, because core dups the recordable and
  # the dup drops Active Storage attachments. So the logo is an Attachable
  # child of the Brand recording, which revise leaves alone.
  class Brand < ActiveRecord::Base
    FIELDS = %i[name tagline description website_url email phone slug].freeze
    CATALOGUE_FIELDS = %i[active metadata].freeze

    self.table_name = "recording_studio_brands"

    recording_studio_recordable label: "Brand", plural_label: "Brands", root: false

    include RecordingStudio::Capabilities::Attachable.to(allowed_content_types: ["image/*"])

    # Set by writers before validation so slug uniqueness can scope to a parent
    # while the Brand row is not yet (or no longer) the recording's recordable.
    attr_accessor :parent_recording_id_for_slug
    # Brand recording id being revised. The still-current snapshot shares the
    # slug until revise finishes, so uniqueness must ignore that recording.
    attr_accessor :slug_uniqueness_except_recording_id

    normalizes :name, :tagline, :description, :email, :phone, :slug, with: ->(value) { value.strip.presence }
    normalizes :website_url, with: ->(value) { Url.normalize(value) }

    before_validation :assign_slug_from_name, if: -> { slug.blank? && name.present? }

    validates :name, presence: true, length: { maximum: 255 }
    validates :slug, presence: true, length: { maximum: 255 }
    validates :tagline, :website_url, :email, :phone, length: { maximum: 255 }
    validates :description, length: { maximum: 5_000 }
    validates :active, inclusion: { in: [true, false] }
    validate :slug_unique_among_current_under_parent
    validate :metadata_must_be_a_hash

    scope :current, lambda {
      joins(<<~SQL.squish)
        INNER JOIN recording_studio_recordings
          ON recording_studio_recordings.recordable_type = #{connection.quote(BRAND_TYPE)}
         AND recording_studio_recordings.recordable_id = #{table_name}.id
      SQL
    }

    scope :under_parent, lambda { |parent_recording|
      current.where(recording_studio_recordings: { parent_recording_id: parent_recording.id })
    }

    scope :active, -> { where(active: true) }

    private

    def assign_slug_from_name
      self.slug = name.to_s.parameterize.presence
    end

    def slug_unique_among_current_under_parent
      return if slug.blank?

      parent_id = parent_recording_id_for_slug.presence || parent_recording_id_from_current_link
      return if parent_id.blank?

      conflict = self.class.current
                     .where(slug: slug, recording_studio_recordings: { parent_recording_id: parent_id })
      conflict = conflict.where.not(id: id) if id
      if slug_uniqueness_except_recording_id.present?
        conflict = conflict.where.not(recording_studio_recordings: { id: slug_uniqueness_except_recording_id })
      end
      return unless conflict.exists?

      errors.add(:slug, :taken)
    end

    def parent_recording_id_from_current_link
      return if id.blank?

      RecordingStudio::Recording.where(recordable_type: BRAND_TYPE, recordable_id: id)
                                .pick(:parent_recording_id)
    end

    def metadata_must_be_a_hash
      return if metadata.is_a?(Hash)

      errors.add(:metadata, "must be a JSON object")
    end
  end
end
