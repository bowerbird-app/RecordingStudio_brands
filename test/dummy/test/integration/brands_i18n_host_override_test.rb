# frozen_string_literal: true

require "test_helper"

class BrandsI18nHostOverrideTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  HOST_OVERRIDE_LOCALE = File.expand_path(
    "../locales/recording_studio_brands.host_override.en.yml",
    __dir__
  ).freeze

  HOST_SUBTITLE =
    "HOST A brand is a distinct identity owned by a company. " \
    "A company can have one brand or manage multiple brands.".freeze

  GEM_SUBTITLE =
    "A brand is a distinct identity owned by a company. " \
    "A company can have one brand or manage multiple brands.".freeze

  def setup
    @original_load_path = I18n.load_path.dup
    @owner = User.create!(email: "brands-i18n-host-#{SecureRandom.hex(4)}@example.com", password: "Password123!")
    @workspace = RecordingStudio.root_recording_for(Workspace.create!(name: "Host Override Workspace"))
    access = RecordingStudioAccessible.bootstrap_owner_access!(recording: @workspace, actor: @owner)
    raise access.error if access.failure?
  end

  def teardown
    I18n.load_path.replace(@original_load_path)
    I18n.reload!
  end

  test "host locale file overrides gem english on a real brands page" do
    sign_in @owner

    with_host_override_locale do
      get recording_studio_brands.recording_brands_path(@workspace)

      assert_response :success
      assert_includes response.body, HOST_SUBTITLE
      refute_match(/(?<!HOST )#{Regexp.escape(GEM_SUBTITLE)}/, response.body)
    end

    get recording_studio_brands.recording_brands_path(@workspace)

    assert_response :success
    assert_includes response.body, GEM_SUBTITLE
    refute_includes response.body, HOST_SUBTITLE
    assert_equal @original_load_path, I18n.load_path
  end

  test "test-only host override is not on the default rails load path" do
    expanded = I18n.load_path.map { |path| File.expand_path(path) }
    gem_locale = File.expand_path("../../../../config/locales/en.yml", __dir__)

    assert_includes expanded, File.expand_path(gem_locale)
    refute_includes expanded, File.expand_path(HOST_OVERRIDE_LOCALE)
    assert_equal @original_load_path, I18n.load_path
  end

  private

  def with_host_override_locale
    original_load_path = I18n.load_path.dup
    expanded_override = File.expand_path(HOST_OVERRIDE_LOCALE)
    gem_locale = File.expand_path("../../../../config/locales/en.yml", __dir__)

    I18n.load_path |= [expanded_override]
    I18n.reload!

    expanded = I18n.load_path.map { |path| File.expand_path(path) }
    assert_operator expanded.index(expanded_override), :>, expanded.index(File.expand_path(gem_locale))

    yield
  ensure
    I18n.load_path.replace(original_load_path)
    I18n.reload!
  end
end
