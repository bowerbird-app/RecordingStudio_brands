# frozen_string_literal: true

class AddCatalogueFieldsToRecordingStudioBrands < ActiveRecord::Migration[8.1]
  SLUG_BACKFILL_SQL = <<~SQL.squish
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

  def change
    add_catalogue_columns
    backfill_slugs
    add_catalogue_indexes
  end

  private

  def add_catalogue_columns
    add_column :recording_studio_brands, :slug, :string
    add_column :recording_studio_brands, :active, :boolean, null: false, default: true
    add_column :recording_studio_brands, :metadata, :jsonb, null: false, default: {}
  end

  def backfill_slugs
    reversible do |dir|
      dir.up { assign_missing_slugs! }
    end
  end

  def assign_missing_slugs!
    execute SLUG_BACKFILL_SQL
    change_column_null :recording_studio_brands, :slug, false
  end

  def add_catalogue_indexes
    add_index :recording_studio_brands, :slug
    add_index :recording_studio_brands, :website_url
    add_index :recording_studio_brands, :active
    add_index :recording_studio_brands, "LOWER(name)", name: "index_recording_studio_brands_on_lower_name"
  end
end
