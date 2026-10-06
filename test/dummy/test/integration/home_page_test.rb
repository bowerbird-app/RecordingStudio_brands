# frozen_string_literal: true

require "test_helper"

class HomePageTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "the home page links to every brand home the user can see" do
    user = create_user("home-owner")
    stranger = create_user("home-stranger")
    studio = owned_workspace("Home Studio", user)
    docs = studio.record(Folder, actor: user) { |folder| folder.name = "Home Docs" }
    studio.record(Page, actor: user) { |page| page.title = "Home Page" }
    hidden = owned_workspace("Hidden Studio", stranger)
    sign_in user

    get root_path

    assert_response :success
    assert_equal(
      {
        "/recording_studio_brands/recordings/#{studio.id}/brands" => "Home Studio Workspace Many brands",
        "/recording_studio_brands/recordings/#{docs.id}/brands" => "Home Docs Folder Many brands"
      },
      css_select("a[href^='/recording_studio_brands/']").to_h { |link| [ link["href"], link.text.squish ] }
    )
    assert_select "a[href=?]", "/recording_studio_brands/recordings/#{hidden.id}/brands", count: 0
  end

  test "a user with no workspaces is told how to get one" do
    sign_in create_user("home-newcomer")

    get root_path

    assert_select "h3", text: "Nothing to show yet"
    assert_select "a[href^='/recording_studio_brands/']", count: 0
  end

  private

  def create_user(prefix)
    User.create!(email: "#{prefix}-#{SecureRandom.hex(4)}@example.com", password: "Password123!")
  end

  def owned_workspace(name, owner)
    workspace = RecordingStudio.root_recording_for(Workspace.create!(name:))
    access = RecordingStudioAccessible.bootstrap_owner_access!(recording: workspace, actor: owner)
    raise access.error if access.failure?

    workspace
  end
end
