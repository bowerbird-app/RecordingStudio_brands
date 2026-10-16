# frozen_string_literal: true

class AddCatalogueFieldsToRecordingStudioBrands < ActiveRecord::Migration[8.1]
  def change
    add_column :recording_studio_brands, :slug, :string
    add_column :recording_studio_brands, :active, :boolean, null: false, default: true
    add_column :recording_studio_brands, :metadata, :jsonb, null: false, default: {}

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE recording_studio_brands
          SET slug = COALESCE(
            NULLIF(
              TRIM(BOTH '-' FROM REGEXP_REPLACE(LOWER(name), '[^a-z0-9]+', '-', 'g')),
              ''
            ),
            REPLACE(id::text, '-', '')
          )
          WHERE slug IS NULL OR slug = ''
        SQL
        change_column_null :recording_studio_brands, :slug, false
      end
    end

    add_index :recording_studio_brands, :slug
    add_index :recording_studio_brands, :website_url
    add_index :recording_studio_brands, :active
    add_index :recording_studio_brands, "LOWER(name)", name: "index_recording_studio_brands_on_lower_name"
  end
end
