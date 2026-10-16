# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class BrandsAdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.find_or_create_by!(email: "brands-admin@example.com") do |user|
      user.password = "Password"
      user.password_confirmation = "Password"
    end
    Current.actor = @user
    @admin_root = AdminRoot.create!(name: "Brands Admin #{SecureRandom.hex(4)}")
    @admin_root_recording = RecordingStudio.root_recording_for(@admin_root)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @admin_root_recording, actor: @user)
    raise result.error if result.failure?
  end

  teardown do
    Current.actor = nil
  end

  test "admin screen lists brands under the admin root" do
    record_brand(name: "Listed brand", slug: "listed-brand", tagline: "On the screen")
    sign_in_and_switch_root

    get "/admin/screens/recording_studio_brands"
    assert_response :success

    get "/admin/screens/recording_studio_brands/table"
    assert_response :success
    assert_includes response.body, "Listed brand"
    assert_includes response.body, "listed-brand"
  end

  test "admin create and update keep the recording id and normalize the website" do
    sign_in_and_switch_root

    get "/recording_studio_brands/admin/brands/new"
    assert_response :success
    assert_includes response.body, "Slug"
    assert_includes response.body, "Active"

    post "/recording_studio_brands/admin/brands", params: {
      brand: {
        name: "Created brand",
        slug: "created-brand",
        website_url: "example.com/press",
        active: "1"
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Created brand"

    recording = RecordingStudio::Recording
                .where(recordable_type: RecordingStudioBrands::BRAND_TYPE, parent_recording: @admin_root_recording)
                .order(:created_at)
                .last
    assert_equal "https://example.com/press", recording.recordable.website_url
    assert_equal "created-brand", recording.recordable.slug
    assert recording.recordable.active?

    get "/recording_studio_brands/admin/brands/#{recording.id}/edit"
    assert_response :success

    patch "/recording_studio_brands/admin/brands/#{recording.id}", params: {
      brand: {
        name: "Created brand",
        slug: "created-brand",
        website_url: "https://example.com/press",
        active: "0"
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_equal recording.id, recording.reload.id
    refute recording.recordable.active?
  end

  test "a viewer cannot create a brand" do
    viewer = User.create!(
      email: "brands-viewer-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    granted = RecordingStudioAccessible.grant_access(
      recording: @admin_root_recording,
      actor: viewer,
      role: :view,
      manager_actor: @user
    )
    raise granted.error if granted.respond_to?(:failure?) && granted.failure?

    sign_in viewer
    switch_root(@admin_root_recording)

    get "/recording_studio_brands/admin/brands/new"
    assert_response :forbidden
  end

  private

  def record_brand(**attributes)
    @admin_root_recording.record(
      RecordingStudioBrands::Brand,
      parent_recording: @admin_root_recording,
      actor: @user
    ) do |brand|
      brand.parent_recording_id_for_slug = @admin_root_recording.id
      brand.assign_attributes(attributes)
    end
  end

  def sign_in_and_switch_root
    sign_in @user
    switch_root(@admin_root_recording)
  end

  def switch_root(root_recording)
    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: root_recording.id,
        return_to: "/"
      }
    }
    assert_response :redirect
  end
end
