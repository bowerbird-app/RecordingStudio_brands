# frozen_string_literal: true

class AddCatalogueFieldsToRecordingStudioBrands < ActiveRecord::Migration[8.1]
  BRAND_TYPE = "RecordingStudioBrands::Brand"

  def change
    add_catalogue_columns
    backfill_catalogue_data
    add_catalogue_indexes
  end

  private

  def add_catalogue_columns
    add_column :recording_studio_brands, :slug, :string
    add_column :recording_studio_brands, :active, :boolean, null: false, default: true
    add_column :recording_studio_brands, :metadata, :jsonb, null: false, default: {}
  end

  def backfill_catalogue_data
    reversible do |dir|
      dir.up do
        assign_missing_slugs!
        normalize_legacy_website_urls!
      end
    end
  end

  def assign_missing_slugs!
    taken = existing_slugs_by_parent
    brands_needing_slugs.each { |row| assign_slug_for_row!(row, taken) }
    change_column_null :recording_studio_brands, :slug, false
  end

  def normalize_legacy_website_urls!
    website_url_rows.each do |row|
      normalized = RecordingStudioBrands::Url.normalize(row["website_url"])
      next if normalized.blank? || normalized == row["website_url"]

      update_brand_website_url!(row["id"], normalized)
    end
  end

  def assign_slug_for_row!(row, taken)
    parent_id = row["parent_recording_id"]
    base = row["name"].to_s.parameterize.presence || row["id"].to_s.delete("-")
    slug = unique_slug(base, taken[parent_id])
    taken[parent_id] << slug
    update_brand_slug!(row["id"], slug)
  end

  def existing_slugs_by_parent
    taken = Hash.new { |hash, key| hash[key] = Set.new }
    brand_slug_rows.each do |row|
      next if row["slug"].blank?

      taken[row["parent_recording_id"]] << row["slug"]
    end
    taken
  end

  def brands_needing_slugs
    brand_slug_rows.select { |row| row["slug"].blank? }
  end

  def brand_slug_rows
    connection.select_all(brand_slug_rows_sql)
  end

  def website_url_rows
    connection.select_all(<<~SQL.squish)
      SELECT id::text AS id, website_url
      FROM recording_studio_brands
      WHERE website_url IS NOT NULL AND website_url <> ''
    SQL
  end

  def brand_slug_rows_sql
    type = quote(BRAND_TYPE)
    "SELECT brands.id::text AS id, brands.name AS name, brands.slug AS slug, " \
      "recordings.parent_recording_id::text AS parent_recording_id " \
      "FROM recording_studio_brands brands " \
      "LEFT JOIN recording_studio_recordings recordings " \
      "ON recordings.recordable_type = #{type} AND recordings.recordable_id = brands.id " \
      "ORDER BY brands.created_at ASC, brands.id ASC"
  end

  def unique_slug(base, taken)
    return base unless taken.include?(base)

    suffix = 2
    loop do
      candidate = "#{base}-#{suffix}"
      return candidate unless taken.include?(candidate)

      suffix += 1
    end
  end

  def update_brand_slug!(id, slug)
    execute(<<~SQL.squish)
      UPDATE recording_studio_brands
      SET slug = #{quote(slug)}
      WHERE id = #{quote(id)}
    SQL
  end

  def update_brand_website_url!(id, website_url)
    execute(<<~SQL.squish)
      UPDATE recording_studio_brands
      SET website_url = #{quote(website_url)}
      WHERE id = #{quote(id)}
    SQL
  end

  def add_catalogue_indexes
    add_index :recording_studio_brands, :slug
    add_index :recording_studio_brands, :website_url
    add_index :recording_studio_brands, :active
    add_index :recording_studio_brands, "LOWER(name)", name: "index_recording_studio_brands_on_lower_name"
  end
end
