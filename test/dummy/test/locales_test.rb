# frozen_string_literal: true

require "test_helper"

class LocalesTest < ActiveSupport::TestCase
  test "rails i18n load path includes the gem english locale file" do
    locale_path = RecordingStudioBrands::Engine.root.join("config/locales/en.yml")

    assert_includes I18n.load_path.map { |path| File.expand_path(path) }, locale_path.to_s
  end

  test "brand interface keys resolve to english in the host app" do
    I18n.with_locale(:en) do
      assert_equal "Brands", I18n.t("recording_studio.brands.titles.brands", raise: true)
      assert_equal "+ Brand", I18n.t("recording_studio.brands.actions.add_brand_plus", raise: true)
      assert_equal "No brands yet", I18n.t("recording_studio.brands.empty.no_brands_title", raise: true)
      assert_equal "Give Client Workspace its public face.",
                   I18n.t("recording_studio.brands.empty.no_brand_description", name: "Client Workspace")
    end
  end
end
