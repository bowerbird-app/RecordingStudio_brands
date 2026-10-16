# frozen_string_literal: true

require "test_helper"

class AdminRegistrationTest < Minitest::Test
  def test_admin_registers_section_screen_and_resource
    assert defined?(RecordingStudioAdmin)

    RecordingStudioBrands::Admin.register!

    assert_equal "brands", RecordingStudioBrands::Admin::BrandsSection.key
    assert_equal "recording_studio_brands", RecordingStudioBrands::Admin::BrandsScreen.key
    assert_equal "brands", RecordingStudioBrands::Admin::BrandsResource.key
    assert_equal :root, RecordingStudioBrands::Admin::BrandsSection.blast_radius

    new_button = RecordingStudioBrands::Admin::BrandsScreen.buttons_value.find { |button| button.name == :new }
    assert new_button
    assert_equal :primary, new_button.style
    assert_respond_to new_button.text, :call
    assert_respond_to new_button.url, :call
    assert_respond_to RecordingStudioBrands::Admin::BrandsScreen.title_value, :call

    with_gem_locale_loaded do
      assert_equal "Add brand", new_button.text.call(nil)
      assert_equal "Brands", RecordingStudioBrands::Admin::BrandsScreen.title_value.call
      RecordingStudioBrands::Admin::BrandsScreen.define_catalogue_table!
      active_column = RecordingStudioBrands::Admin::BrandsScreen.table_value.columns.find { |column| column.key == :active }
      assert_equal "Active", active_column.title
      assert_equal :badge, active_column.display
      assert_respond_to active_column.display_options, :call
      slug_column = RecordingStudioBrands::Admin::BrandsScreen.table_value.columns.find { |column| column.key == :slug }
      assert_equal "Slug", slug_column.title
    end
  end

  def test_configuration_defaults_include_mount_path
    assert_equal "/recording_studio_brands", RecordingStudioBrands.configuration.mount_path
  end

  private

  def with_gem_locale_loaded
    locale_path = File.expand_path("../config/locales/en.yml", __dir__)
    original_load_path = I18n.load_path.dup
    I18n.load_path |= [File.expand_path(locale_path)]
    I18n.reload!
    yield
  ensure
    I18n.load_path.replace(original_load_path)
    I18n.reload!
  end
end
