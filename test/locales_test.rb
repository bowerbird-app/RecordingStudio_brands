# frozen_string_literal: true

require "test_helper"
require "yaml"

class RecordingStudioBrandsLocalesTest < Minitest::Test
  # I18n interpolation tokens use %{name}; Style/FormatStringToken wants %<name>s.
  # rubocop:disable-next Style/FormatStringToken
  BRAND_KEYS = {
    "titles" => {
      "brand" => "Brand",
      "brands" => "Brands",
      "add_brand" => "Add brand",
      "edit_brand" => "Edit brand"
    },
    "actions" => {
      "edit_brand" => "Edit brand",
      "save_brand" => "Save brand",
      "add_brand" => "Add brand",
      "add_brand_plus" => "+ Brand",
      "change_logo" => "Change logo",
      "add_logo" => "Add logo"
    },
    "labels" => {
      "name" => "Name",
      "slug" => "Slug",
      "tagline" => "Tagline",
      "description" => "Description",
      "website" => "Website",
      "email" => "Email",
      "phone" => "Phone",
      "active" => "Active",
      "active_yes" => "Yes",
      "active_no" => "No"
    },
    "help" => {
      "slug" => "Used in seeds and catalogue lookups. Leave blank to build it from the name.",
      "active" => "Off hides the brand from live catalogue lists."
    },
    "placeholders" => {
      "website" => "https://"
    },
    "admin" => {
      "new_subtitle" => "Saved under the root you have open.",
      "section_title" => "Brands",
      "section_subtitle" => "Public names under this root.",
      "catalogue_link" => "Brands",
      "new_link" => "New",
      "screen_title" => "Brands",
      "screen_subtitle" => "Names, slugs, and whether each brand is live.",
      "table_title" => "Brands",
      "updated_column" => "Updated",
      "resource_title" => "Brands",
      "show_action" => "Show",
      "edit_action" => "Edit",
      "new_action" => "New"
    },
    "empty" => {
      "no_brands_title" => "No brands yet",
      "no_brands_description" => "Add the first one to get going.",
      "no_brand_title" => "No brand yet",
      "no_brand_description" => "Give %{name} its public face."
    },
    "many" => {
      "subtitle" =>
        "A brand is a distinct identity owned by a company. " \
        "A company can have one brand or manage multiple brands."
    },
    "new" => {
      "subtitle" => "You can add a logo once it's saved."
    },
    "conflict" => {
      "title" => "This %{type} has more than one brand",
      "description" => "A %{type} holds just one. You can still open and edit each brand below."
    },
    "flashes" => {
      "brand_saved" => "Brand saved.",
      "logo_saved" => "Logo saved.",
      "logo_not_saved" => "The logo could not be saved. Choose an image file.",
      "brand_limit" => "This %{type} already has a brand.",
      "brand_invalid" => "Check the brand and try again.",
      "admin_root_missing" => "Pick a root that holds brands, then try again."
    }
  }.freeze

  def test_engine_ships_only_english_locale_files
    files = Dir[File.join(engine_locales_dir, "*")].map { |path| File.basename(path) }

    assert_equal ["en.yml"], files.sort
  end

  def test_english_brand_keys_resolve_without_missing_translations
    with_gem_locale_loaded do
      I18n.with_locale(:en) do
        each_leaf_key(BRAND_KEYS) do |parts, english|
          full_key = "recording_studio.brands.#{parts.join('.')}"
          translation = I18n.t(full_key, default: nil)

          assert_equal english, translation, "#{full_key} should resolve to #{english.inspect}"
          assert_equal english, I18n.t(full_key, raise: true)
        end

        assert_equal "Give Studio its public face.",
                     I18n.t("recording_studio.brands.empty.no_brand_description", name: "Studio")
        assert_equal "This workspace has more than one brand",
                     I18n.t("recording_studio.brands.conflict.title", type: "workspace")
        assert_equal "This workspace already has a brand.",
                     I18n.t("recording_studio.brands.flashes.brand_limit", type: "workspace")
        assert_equal "Website",
                     I18n.t("activerecord.attributes.recording_studio_brands/brand.website_url", raise: true)
        assert_equal "must be a JSON object",
                     I18n.t(
                       "activerecord.errors.models.recording_studio_brands/brand.attributes.metadata.not_a_hash",
                       raise: true
                     )
      end
    end
  end

  def test_en_yml_nests_keys_under_recording_studio_brands
    tree = locale_tree(File.join(engine_locales_dir, "en.yml"), "en")
           .fetch("recording_studio")
           .fetch("brands")

    assert_equal BRAND_KEYS, deep_stringify(tree)
  end

  private

  def engine_locales_dir
    File.expand_path("../config/locales", __dir__)
  end

  def locale_path
    File.join(engine_locales_dir, "en.yml")
  end

  def locale_tree(path, locale)
    YAML.safe_load_file(path, aliases: true).fetch(locale)
  end

  def deep_stringify(value)
    case value
    when Hash then value.to_h { |key, child| [key.to_s, deep_stringify(child)] }
    else value
    end
  end

  def each_leaf_key(tree, parts = [], &block)
    tree.each do |key, value|
      next_parts = parts + [key]
      if value.is_a?(Hash)
        each_leaf_key(value, next_parts, &block)
      else
        yield next_parts, value
      end
    end
  end

  def with_gem_locale_loaded
    original_load_path = I18n.load_path.dup
    expanded = File.expand_path(locale_path)
    I18n.load_path |= [expanded]
    I18n.reload!
    yield
  ensure
    I18n.load_path.replace(original_load_path)
    I18n.reload!
  end
end
