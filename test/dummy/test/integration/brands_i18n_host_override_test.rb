# frozen_string_literal: true

require "test_helper"

class BrandsI18nHostOverrideTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @original_load_path = I18n.load_path.dup
    @owner = User.create!(email: "brands-i18n-host-#{SecureRandom.hex(4)}@example.com", password: "Password123!")
    @workspace = RecordingStudio.root_recording_for(Workspace.create!(name: "Host Override Workspace"))
    access = RecordingStudioAccessible.bootstrap_owner_access!(recording: @workspace, actor: @owner)
    raise access.error if access.failure?
  end

  def teardown
    I18n.load_path = @original_load_path
    I18n.reload!
  end

  test "host locale file overrides gem english on a real brands page" do
    sign_in @owner

    get recording_studio_brands.recording_brands_path(@workspace)

    assert_response :success
    assert_includes response.body, "HOST A brand is a distinct identity owned by a company. A company can have one brand or manage multiple brands."
    refute_match(
      /(?<!HOST )A brand is a distinct identity owned by a company\. A company can have one brand or manage multiple brands\./,
      response.body
    )
    assert_equal @original_load_path, I18n.load_path
  end

  test "dummy host override file is on the rails load path after the gem locale" do
    gem_locale = File.expand_path("../../../../config/locales/en.yml", __dir__)
    host_locale = File.expand_path("../../config/locales/recording_studio_brands.host_override.en.yml", __dir__)
    expanded = I18n.load_path.map { |path| File.expand_path(path) }

    assert_includes expanded, File.expand_path(gem_locale)
    assert_includes expanded, File.expand_path(host_locale)
    assert_operator expanded.index(File.expand_path(host_locale)), :>,
                    expanded.index(File.expand_path(gem_locale))
    assert_equal @original_load_path, I18n.load_path
  end
end
