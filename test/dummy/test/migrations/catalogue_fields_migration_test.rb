# frozen_string_literal: true

require_relative "../test_helper"

class CatalogueFieldsMigrationTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  ENGINE_MIGRATION = File.expand_path(
    "../../../../db/migrate/20261016000001_add_catalogue_fields_to_recording_studio_brands.rb",
    __dir__
  )

  setup do
    load ENGINE_MIGRATION
    @connection = ActiveRecord::Base.connection
    @migration = AddCatalogueFieldsToRecordingStudioBrands.new
    @migration.verbose = false
  end

  teardown do
    restore_saved_tables
    RecordingStudioBrands::Brand.reset_column_information
    RecordingStudio::Recording.reset_column_information
    @connection.schema_cache.clear!
  end

  test "backfill parameterizes cafe and suffixes duplicate names under one parent" do
    parent_id = SecureRandom.uuid
    cafe_id = SecureRandom.uuid
    first_acme_id = SecureRandom.uuid
    second_acme_id = SecureRandom.uuid

    with_pre_catalogue_tables do
      insert_brand(cafe_id, "Café")
      insert_brand(first_acme_id, "Acme")
      insert_brand(second_acme_id, "Acme")
      insert_recording(parent_id, cafe_id)
      insert_recording(parent_id, first_acme_id)
      insert_recording(parent_id, second_acme_id)

      @migration.send(:add_catalogue_columns)
      @migration.send(:assign_missing_slugs!)
      @connection.schema_cache.clear!

      slugs = slug_by_id
      assert_equal "cafe", slugs[cafe_id]
      assert_equal "acme", slugs[first_acme_id]
      assert_equal "acme-2", slugs[second_acme_id]
      refute column_nullable?(:slug)
    end
  end

  test "backfill normalizes legacy website_url and keeps brand ids" do
    brand_id = SecureRandom.uuid
    parent_id = SecureRandom.uuid

    with_pre_catalogue_tables do
      insert_brand(brand_id, "Nike", website_url: "WWW.NIKE.COM/path/?utm_source=old")
      insert_recording(parent_id, brand_id)

      @migration.send(:add_catalogue_columns)
      @migration.send(:assign_missing_slugs!)
      @migration.send(:normalize_legacy_website_urls!)
      @connection.schema_cache.clear!

      row = @connection.select_one(<<~SQL.squish)
        SELECT id::text AS id, website_url, slug
        FROM recording_studio_brands
        WHERE id = #{@connection.quote(brand_id)}
      SQL

      assert_equal brand_id, row["id"]
      assert_equal "nike", row["slug"]
      assert_equal "https://www.nike.com/path", row["website_url"]
    end
  end

  test "catalogue columns can be removed while brand ids stay" do
    brand_id = SecureRandom.uuid
    parent_id = SecureRandom.uuid

    with_pre_catalogue_tables do
      insert_brand(brand_id, "Rollback Brand")
      insert_recording(parent_id, brand_id)

      @migration.send(:add_catalogue_columns)
      @migration.send(:assign_missing_slugs!)
      @connection.schema_cache.clear!
      assert column_exists?(:slug)
      assert_equal brand_id, brand_id_value(brand_id)

      @connection.change_column_null :recording_studio_brands, :slug, true
      @connection.remove_column :recording_studio_brands, :slug
      @connection.remove_column :recording_studio_brands, :active
      @connection.remove_column :recording_studio_brands, :metadata
      @connection.schema_cache.clear!

      refute column_exists?(:slug)
      refute column_exists?(:active)
      refute column_exists?(:metadata)
      assert_equal brand_id, brand_id_value(brand_id)
    end
  end

  private

  def with_pre_catalogue_tables
    @connection.transaction do
      install_pre_catalogue_tables
      yield
      raise ActiveRecord::Rollback
    end
  ensure
    restore_saved_tables
  end

  def install_pre_catalogue_tables
    @connection.rename_table :recording_studio_brands, :recording_studio_brands_saved
    @connection.rename_table :recording_studio_recordings, :recording_studio_recordings_saved

    @connection.create_table :recording_studio_brands, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.string :name, null: false
      table.string :tagline
      table.text :description
      table.string :website_url
      table.string :email
      table.string :phone
      table.timestamps null: false
    end

    @connection.create_table :recording_studio_recordings, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.string :recordable_type, null: false
      table.uuid :recordable_id, null: false
      table.uuid :parent_recording_id
      table.uuid :root_recording_id
      table.timestamps null: false
    end
  end

  def restore_saved_tables
    return unless @connection&.table_exists?(:recording_studio_brands_saved)

    @connection.drop_table :recording_studio_brands if @connection.table_exists?(:recording_studio_brands)
    @connection.drop_table :recording_studio_recordings if @connection.table_exists?(:recording_studio_recordings)
    @connection.rename_table :recording_studio_brands_saved, :recording_studio_brands
    @connection.rename_table :recording_studio_recordings_saved, :recording_studio_recordings
  end

  def insert_brand(id, name, website_url: nil)
    now = @connection.quote(Time.current)
    @connection.execute(<<~SQL.squish)
      INSERT INTO recording_studio_brands (id, name, website_url, created_at, updated_at)
      VALUES (
        #{@connection.quote(id)},
        #{@connection.quote(name)},
        #{website_url.nil? ? 'NULL' : @connection.quote(website_url)},
        #{now},
        #{now}
      )
    SQL
  end

  def insert_recording(parent_id, brand_id)
    now = @connection.quote(Time.current)
    @connection.execute(<<~SQL.squish)
      INSERT INTO recording_studio_recordings (
        id, recordable_type, recordable_id, parent_recording_id, root_recording_id, created_at, updated_at
      ) VALUES (
        #{@connection.quote(SecureRandom.uuid)},
        #{@connection.quote("RecordingStudioBrands::Brand")},
        #{@connection.quote(brand_id)},
        #{@connection.quote(parent_id)},
        #{@connection.quote(parent_id)},
        #{now},
        #{now}
      )
    SQL
  end

  def slug_by_id
    @connection.select_rows("SELECT id::text, slug FROM recording_studio_brands").to_h
  end

  def column_nullable?(name)
    value = @connection.select_value(<<~SQL.squish)
      SELECT is_nullable
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'recording_studio_brands'
        AND column_name = #{@connection.quote(name)}
    SQL
    value == "YES"
  end

  def column_exists?(name)
    @connection.column_exists?(:recording_studio_brands, name)
  end

  def brand_id_value(id)
    @connection.select_value(
      "SELECT id::text FROM recording_studio_brands WHERE id = #{@connection.quote(id)}"
    )
  end
end
