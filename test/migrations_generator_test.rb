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

      assert_equal ["create_recording_studio_brands.rb"], names
      assert_includes File.read(copied.first), "create_table :recording_studio_brands, id: :uuid"
    end
  end

  private

  def run_generator(destination_root)
    capture_io do
      RecordingStudioBrands::Generators::MigrationsGenerator.new([], {}, destination_root:).invoke_all
    end
  end
end
