# frozen_string_literal: true

require "test_helper"

class BrandsApiTest < ActionDispatch::IntegrationTest
  setup do
    skip unless defined?(RecordingStudioApi)
    assert_equal RecordingStudioBrands::Brand::FIELDS, RecordingStudioBrands::Api.writable_attributes

    @owner = User.create!(email: "api-owner-#{SecureRandom.hex(4)}@example.com", password: "Password123!")
    @workspace = RecordingStudio.root_recording_for(Workspace.create!(name: "API Workspace #{SecureRandom.hex(4)}"))
    owner_access = RecordingStudioAccessible.bootstrap_owner_access!(recording: @workspace, actor: @owner)
    raise owner_access.error if owner_access.failure?

    @other = RecordingStudio.root_recording_for(Workspace.create!(name: "Other Workspace #{SecureRandom.hex(4)}"))
    other_owner = User.create!(email: "api-other-#{SecureRandom.hex(4)}@example.com", password: "Password123!")
    other_access = RecordingStudioAccessible.bootstrap_owner_access!(recording: @other, actor: other_owner)
    raise other_access.error if other_access.failure?

    Current.actor = @owner
    @brand = record_brand(@workspace, "Acme Coffee")
    @foreign_brand = record_brand(@other, "Acme Coffee", actor: other_owner)
  end

  teardown do
    Current.actor = nil
  end

  test "brands index show create and update return 401 403 and 200" do
    path = "/recording_studio_api/api/v1/brands"
    view_token = workspace_token(:view)
    edit_token = workspace_token(:edit)

    get path
    assert_response :unauthorized

    get path, headers: bearer(view_token)
    assert_response :success
    listed_ids = JSON.parse(response.body).fetch("records").map { |record| record.fetch("id") }
    assert_includes listed_ids, @brand.id
    refute_includes listed_ids, @foreign_brand.id

    get "#{path}/#{@brand.id}", headers: bearer(view_token)
    assert_response :success
    shown = JSON.parse(response.body)
    assert_equal "Acme Coffee", shown.fetch("name")
    assert_equal true, shown.fetch("active")
    assert_equal({}, shown.fetch("metadata"))

    get "#{path}?filter[slug]=#{@brand.recordable.slug}", headers: bearer(view_token)
    assert_response :success
    assert_equal [@brand.id], JSON.parse(response.body).fetch("records").map { |record| record.fetch("id") }

    get "#{path}?filter[name]=ACME COFFEE", headers: bearer(view_token)
    assert_response :success
    assert_equal [@brand.id], JSON.parse(response.body).fetch("records").map { |record| record.fetch("id") }

    get "#{path}/#{@foreign_brand.id}", headers: bearer(view_token)
    assert_response :not_found

    post path, params: { parent_id: @workspace.id, name: "From view" }.to_json, headers: bearer(view_token)
    assert_response :forbidden

    post path, params: { parent_id: @workspace.id, name: "From edit" }.to_json, headers: bearer(edit_token)
    assert_response :created
    created = JSON.parse(response.body)
    assert_equal "From edit", created.fetch("name")
    assert_equal "from-edit", created.fetch("slug")

    patch "#{path}/#{created.fetch("id")}", params: { tagline: "Roasted daily" }.to_json, headers: bearer(view_token)
    assert_response :forbidden

    patch "#{path}/#{created.fetch("id")}", params: { tagline: "Roasted daily" }.to_json, headers: bearer(edit_token)
    assert_response :success
    assert_equal "Roasted daily", JSON.parse(response.body).fetch("tagline")
    assert_equal created.fetch("id"), JSON.parse(response.body).fetch("id")

    delete "#{path}/#{created.fetch("id")}", headers: bearer(edit_token)
    assert_response :unprocessable_content
    assert_equal "destroy is not enabled for RecordingStudioBrands::Brand",
                 JSON.parse(response.body).dig("error", "message")
    assert RecordingStudio::Recording.exists?(created.fetch("id"))
  end

  private

  def record_brand(parent, name, actor: @owner)
    parent.record(RecordingStudioBrands::Brand, parent_recording: parent, actor: actor) do |brand|
      brand.parent_recording_id_for_slug = parent.id
      brand.name = name
    end
  end

  def workspace_token(role)
    provision = RecordingStudioApi::Services::ProvisionApiClient.call(
      api: :public,
      access_point_recording: @workspace,
      manager_actor: @owner,
      role: role,
      name: "Brands #{role} #{SecureRandom.hex(4)}"
    )
    raise provision.error unless provision.success?

    issued = RecordingStudioApi::Services::IssueOauthAccessToken.call(
      api: :public,
      grant_type: "client_credentials",
      client_id: provision.value.fetch(:credential).oauth_client_id,
      client_secret: provision.value.fetch(:token)
    )
    raise issued.error unless issued.success?

    issued.value.fetch(:access_token)
  end

  def bearer(token)
    { "Authorization" => "Bearer #{token}", "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
  end
end
