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
  end

  def test_configuration_defaults_include_mount_path
    assert_equal "/recording_studio_brands", RecordingStudioBrands.configuration.mount_path
  end
end
