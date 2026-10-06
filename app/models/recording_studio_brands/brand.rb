# frozen_string_literal: true

module RecordingStudioBrands
  # Names no allowed_parent_types. Parent types opt in through
  # RecordingStudio::Capabilities::Brand, so the gem never names host models.
  #
  # Every revise saves a new Brand row, because core dups the recordable and
  # the dup drops Active Storage attachments. So the logo is an Attachable
  # child of the Brand recording, which revise leaves alone.
  class Brand < ActiveRecord::Base
    FIELDS = %i[name tagline description website_url email phone].freeze

    self.table_name = "recording_studio_brands"

    recording_studio_recordable label: "Brand", plural_label: "Brands", root: false

    include RecordingStudio::Capabilities::Attachable.to(allowed_content_types: ["image/*"])

    normalizes(*FIELDS, with: ->(value) { value.strip.presence })

    validates :name, presence: true, length: { maximum: 255 }
    validates :tagline, :website_url, :email, :phone, length: { maximum: 255 }
    validates :description, length: { maximum: 5_000 }
  end
end
