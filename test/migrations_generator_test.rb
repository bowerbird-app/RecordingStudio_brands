# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "generators/recording_studio_brands/migrations/migrations_generator"

class MigrationsGeneratorTest < Minitest::Test
  def test_copies_the_brands_migration_once_across_two_runs
    Dir.mktmpdir do |dir|
      run_generator(dir)
      run_generator(dir)

      copied = Dir[File.join(dir, "db/migrate/*.rb")]
      names = copied.map { |path| File.basename(path).sub(/\A\d+_/, "") }

      assert_equal %w[
        add_catalogue_fields_to_recording_studio_brands.rb
        create_recording_studio_brands.rb
      ], names.sort
      create = copied.find { |path| File.basename(path).include?("create_recording_studio_brands") }
      catalogue = copied.find { |path| File.basename(path).include?("add_catalogue_fields") }
      assert_includes File.read(create), "create_table :recording_studio_brands, id: :uuid"
      assert_includes File.read(catalogue), "add_column :recording_studio_brands, :slug, :string"
    end
  end

  private

  def run_generator(destination_root)
    capture_io do
      RecordingStudioBrands::Generators::MigrationsGenerator.new([], {}, destination_root:).invoke_all
    end
  end
end
