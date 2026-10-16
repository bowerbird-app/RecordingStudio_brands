# frozen_string_literal: true

require "test_helper"

class BrandsFlashesI18nTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = User.create!(email: "brands-flashes-#{SecureRandom.hex(4)}@example.com", password: "Password123!")
    @workspace = RecordingStudio.root_recording_for(Workspace.create!(name: "Flashes Workspace"))
    access = RecordingStudioAccessible.bootstrap_owner_access!(recording: @workspace, actor: @owner)
    raise access.error if access.failure?

    @folder = @workspace.record(Folder, actor: @owner) { |folder| folder.name = "Campaigns" }
    @brand = record_brand(@folder, "Nike")
  end

  test "create and update flashes render main english" do
    sign_in @owner

    post recording_studio_brands.recording_brands_path(@folder), params: { brand: { name: "Dove" } }

    assert_redirected_to recording_studio_brands.brand_path(brand_recordings_under(@folder).last)
    assert_equal "Brand saved.", flash[:notice]

    patch recording_studio_brands.brand_path(@brand), params: { brand: { name: "Nike", tagline: "Just Do It" } }

    assert_redirected_to recording_studio_brands.brand_path(@brand)
    assert_equal "Brand saved.", flash[:notice]
  end

  test "logo flashes render main english" do
    sign_in @owner

    patch recording_studio_brands.brand_logo_path(@brand), params: {
      logo: Rack::Test::UploadedFile.new(StringIO.new("nike-bytes"), "image/png", original_filename: "nike.png")
    }

    assert_redirected_to recording_studio_brands.brand_path(@brand)
    assert_equal "Logo saved.", flash[:notice]

    patch recording_studio_brands.brand_logo_path(@brand)

    assert_redirected_to recording_studio_brands.brand_path(@brand)
    assert_equal "The logo could not be saved. Choose an image file.", flash[:alert]
  end

  test "brand limit flash renders main english with parent type label" do
    with_brand_options(Workspace, allows: :one) do
      record_brand(@workspace, "Taylor Swift")
      sign_in @owner

      get recording_studio_brands.new_recording_brand_path(@workspace)

      assert_redirected_to recording_studio_brands.recording_brands_path(@workspace)
      assert_equal "This workspace already has a brand.", flash[:alert]
    end
  end

  test "translated locale changes flash text without changing english defaults" do
    original_locales = I18n.available_locales
    sign_in @owner

    I18n.available_locales = original_locales | [:fr]
    I18n.backend.store_translations(:fr, {
      recording_studio: {
        brands: {
          flashes: {
            brand_saved: "Marque enregistrée."
          }
        }
      }
    })

    I18n.with_locale(:fr) do
      patch recording_studio_brands.brand_path(@brand), params: { brand: { name: "Nike", tagline: "Just Do It" } }

      assert_redirected_to recording_studio_brands.brand_path(@brand)
      assert_equal "Marque enregistrée.", flash[:notice]
    end

    I18n.with_locale(:en) do
      patch recording_studio_brands.brand_path(@brand), params: { brand: { name: "Nike", tagline: "Just Do It" } }

      assert_equal "Brand saved.", flash[:notice]
    end
  ensure
    I18n.available_locales = original_locales
    I18n.reload!
  end

  private

  def record_brand(parent, name)
    parent.record(RecordingStudioBrands::Brand, parent_recording: parent, actor: @owner) do |brand|
      brand.parent_recording_id_for_slug = parent.id
      brand.name = name
    end
  end

  def brand_recordings_under(parent)
    RecordingStudio::Recording.where(parent_recording: parent, recordable_type: "RecordingStudioBrands::Brand")
                              .order(:created_at, :id)
  end

  def with_brand_options(model, **options)
    original = RecordingStudio.capability_options(:brand, for: model)
    RecordingStudio.set_capability_options(:brand, on: model, **options)
    yield
  ensure
    RecordingStudio.set_capability_options(:brand, on: model, **original)
  end
end
