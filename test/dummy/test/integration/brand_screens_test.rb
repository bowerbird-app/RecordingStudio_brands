# frozen_string_literal: true

require "test_helper"

class BrandScreensTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  TAYLOR = {
    name: "Taylor Swift",
    tagline: "The Eras Tour",
    description: "Singer and songwriter.",
    website_url: "https://www.taylorswift.com",
    email: "hello@taylorswift.com",
    phone: "+1 615 555 0100"
  }.freeze

  setup do
    @owner = create_user("screens-owner")
    @viewer = create_user("screens-viewer")
    @workspace = RecordingStudio.root_recording_for(Workspace.create!(name: "Screens Workspace"))
    owner_access = RecordingStudioAccessible.bootstrap_owner_access!(recording: @workspace, actor: @owner)
    raise owner_access.error if owner_access.failure?

    viewer_access = RecordingStudioAccessible.grant_access(
      recording: @workspace, actor: @viewer, role: :view, manager_actor: @owner
    )
    raise viewer_access.error if viewer_access.failure?

    @folder = @workspace.record(Folder, actor: @owner) { |folder| folder.name = "Campaigns" }
  end

  test "an empty workspace lists brands and offers to add another" do
    sign_in @owner

    get brands.recording_brands_path(@workspace)

    assert_response :success
    assert_select "h1", text: "Brands"
    assert_includes page_text, "A brand is a distinct identity owned by a company. A company can have one brand or manage multiple brands."
    assert_select ".md\\:grid-cols-2" do
      assert_select "h3", text: "No brands yet"
    end
    assert_select "a[href=?]", brands.new_recording_brand_path(@workspace), text: "+ Brand"
  end

  test "adding the workspace brand saves every field and shows it in place of the empty state" do
    sign_in @owner
    get brands.new_recording_brand_path(@workspace)

    assert_equal %w[brand[name] brand[tagline] brand[description] brand[website_url] brand[email] brand[phone]],
                 css_select("form [name^='brand[']").map { |field| field["name"] }

    post brands.recording_brands_path(@workspace), params: { brand: TAYLOR }

    taylor = brand_recordings_under(@workspace).sole
    assert_redirected_to brands.brand_path(taylor)
    assert_equal "Brand saved.", flash[:notice]
    assert_equal TAYLOR, brand_recordings_under(@workspace).sole.recordable.slice(*TAYLOR.keys).symbolize_keys

    follow_redirect!

    assert_select "h1", text: "Brand"
    assert_select "h2", text: "Taylor Swift"
    assert_select ".max-w-2xl", count: 1
    assert_select "input[type=file]", count: 0
    assert_select ".max-w-2xl" do
      assert_select "h2", text: "Taylor Swift"
      assert_select "a[href=?]", "https://www.taylorswift.com"
    end
    assert_includes page_text, "The Eras Tour"
    assert_includes page_text, "Singer and songwriter."
    assert_select "a[href=?]", "https://www.taylorswift.com", text: "https://www.taylorswift.com"
    assert_select "a[href=?]", "mailto:hello@taylorswift.com", text: "hello@taylorswift.com"
    assert_select "a[href=?]", "tel:+1 615 555 0100", text: "+1 615 555 0100"
    assert_select "a", text: "Add brand", count: 0
  end

  test "a full workspace sends Add back to its brand" do
    with_brand_options(Workspace, allows: :one) do
      record_brand(@workspace, "Taylor Swift")
      sign_in @owner

      get brands.new_recording_brand_path(@workspace)

      assert_redirected_to brands.recording_brands_path(@workspace)
      assert_equal "This workspace already has a brand.", flash[:alert]
    end
  end

  test "a second brand posted to a full workspace saves nothing" do
    with_brand_options(Workspace, allows: :one) do
      record_brand(@workspace, "Taylor Swift")
      sign_in @owner

      assert_no_difference -> { RecordingStudioBrands::Brand.count } do
        post brands.recording_brands_path(@workspace), params: { brand: { name: "Taylor's Version" } }
      end

      assert_redirected_to brands.recording_brands_path(@workspace)
      assert_equal "This workspace already has a brand.", flash[:alert]
      assert_equal [ "Taylor Swift" ], brand_names_under(@workspace)
    end
  end

  test "editing the workspace brand revises it in place" do
    taylor = record_brand(@workspace, "Taylor Swift")
    sign_in @owner

    get brands.edit_brand_path(taylor)

    assert_select "input[name='brand[name]'][value=?]", "Taylor Swift"

    patch brands.brand_path(taylor), params: { brand: { name: "Taylor Swift", tagline: "Midnights" } }

    assert_redirected_to brands.brand_path(taylor)
    assert_equal "Brand saved.", flash[:notice]
    assert_equal [ taylor.id ], brand_recordings_under(@workspace).map(&:id)
    assert_equal "Midnights", RecordingStudio::Recording.find(taylor.id).recordable.tagline
  end

  test "a brand without a name comes back with the error and saves nothing" do
    taylor = record_brand(@workspace, "Taylor Swift")
    sign_in @owner

    patch brands.brand_path(taylor), params: { brand: { name: " ", tagline: "Midnights" } }

    assert_response :unprocessable_content
    assert_includes page_text, "Name can't be blank"
    assert_select "input[name='brand[tagline]'][value=?]", "Midnights"
    assert_equal({ "name" => "Taylor Swift", "tagline" => nil },
                 RecordingStudio::Recording.find(taylor.id).recordable.slice(:name, :tagline))

    assert_no_difference -> { RecordingStudioBrands::Brand.count } do
      post brands.recording_brands_path(@folder), params: { brand: { name: "", tagline: "Just Do It" } }
    end

    assert_response :unprocessable_content
    assert_includes page_text, "Name can't be blank"
    assert_select "input[name='brand[tagline]'][value=?]", "Just Do It"
  end

  test "a folder lists its brands in order and adds more" do
    nike = record_brand(@folder, "Nike")
    dove = record_brand(@folder, "Dove")
    acme = record_brand(@folder, "Acme Coffee")
    sign_in @owner

    get brands.recording_brands_path(@folder)

    assert_equal [ "Nike", "Dove", "Acme Coffee" ], list_links.map { |link| link.at("p").text }
    assert_equal [ nike, dove, acme ].map { |recording| brands.brand_path(recording) }, list_links.pluck("href")
    assert_select "h1", text: "Brands"
    assert_select ".md\\:grid-cols-2 ul[role=list]"
    assert_select "a[href=?]", brands.new_recording_brand_path(@folder), text: "+ Brand"

    post brands.recording_brands_path(@folder), params: { brand: { name: "Ben & Jerry's" } }

    assert_redirected_to brands.brand_path(brand_recordings_under(@folder).last)
    assert_equal [ "Nike", "Dove", "Acme Coffee", "Ben & Jerry's" ], brand_names_under(@folder)
  end

  test "a workspace left with two brands lists both, warns, and still refuses a third" do
    nike = record_brand(@workspace, "Nike")
    dove = record_brand(@workspace, "Dove")
    sign_in @owner

    with_brand_options(Workspace, allows: :one) do
      get brands.recording_brands_path(@workspace)

      assert_response :success
      assert_includes page_text, "This workspace has more than one brand"
      assert_select ".md\\:grid-cols-2 ul[role=list]"
      assert_equal [ brands.brand_path(nike), brands.brand_path(dove) ], list_links.pluck("href")
      assert_select "a", text: "+ Brand", count: 0

      post brands.recording_brands_path(@workspace), params: { brand: { name: "Acme Coffee" } }

      assert_redirected_to brands.recording_brands_path(@workspace)
      assert_equal [ "Nike", "Dove" ], brand_names_under(@workspace)
    end
  end

  test "a viewer sees brands but cannot add or change them" do
    taylor = record_brand(@workspace, "Taylor Swift")
    sign_in @viewer

    get brands.recording_brands_path(@workspace)

    assert_select "h1", text: "Brands"
    assert_select "a", text: "+ Brand", count: 0
    assert_select "a", text: "Edit brand", count: 0
    assert_select "input[type=file]", count: 0

    get brands.recording_brands_path(@folder)

    assert_select "h3", text: "No brands yet"
    assert_select "a", text: "+ Brand", count: 0

    get brands.new_recording_brand_path(@folder)
    assert_response :forbidden
    get brands.edit_brand_path(taylor)
    assert_response :forbidden
    patch brands.brand_path(taylor), params: { brand: { name: "Taylor's Version" } }
    assert_response :forbidden
    post brands.recording_brands_path(@folder), params: { brand: { name: "Nike" } }
    assert_response :forbidden

    assert_equal [ "Taylor Swift" ], brand_names_under(@workspace)
    assert_equal [], brand_names_under(@folder)

    sign_in @owner
    get brands.recording_brands_path(@workspace)

    assert_select "a[href=?]", brands.new_recording_brand_path(@workspace), text: "+ Brand"
    assert_select "input[type=file]", count: 0

    get brands.brand_path(taylor)

    assert_select "a[href=?]", brands.edit_brand_path(taylor), text: "Edit brand"

    get brands.edit_brand_path(taylor)

    assert_select "form[action=?] input[type=file][name=logo]", brands.brand_logo_path(taylor), count: 1
    assert_select "button", text: "Add logo", count: 1
    assert_select "button", text: "Upload logo", count: 0
    assert_select "button", text: "Replace logo", count: 0
  end

  test "a page has no brand screens" do
    page = @workspace.record(Page, actor: @owner) { |record| record.title = "Press" }
    sign_in @owner

    get brands.recording_brands_path(@folder)
    assert_response :success

    get brands.recording_brands_path(page)
    assert_response :not_found
    get brands.new_recording_brand_path(page)
    assert_response :not_found
  end

  test "a signed-out visitor is sent to sign in" do
    get brands.recording_brands_path(@workspace)

    assert_redirected_to new_user_session_path
  end

  test "brand fields render as text" do
    script = "<script>alert('name')</script>"
    brand_recording = record_brand(@folder, script) do |brand|
      brand.tagline = "<b>bold</b>"
      brand.website_url = "javascript:alert('site')"
    end
    sign_in @owner

    [ brands.brand_path(brand_recording), brands.recording_brands_path(@folder) ].each do |path|
      get path

      assert_includes page_text, script
      assert_includes page_text, "<b>bold</b>"
      assert_select "script", text: /alert\('name'\)/, count: 0
      assert_select "b", text: "bold", count: 0
    end
  end

  test "only a full web address becomes a website link" do
    bare = record_brand(@folder, "Nike") { |brand| brand.website_url = "nike.com" }
    unsafe = record_brand(@folder, "Dove") { |brand| brand.website_url = "javascript:alert('site')" }
    malformed = record_brand(@folder, "Rexona") { |brand| brand.website_url = "https://rexona .example" }
    full = record_brand(@folder, "Acme Coffee") { |brand| brand.website_url = "https://acme.example/coffee" }
    sign_in @owner

    get brands.brand_path(full)

    assert_select "a[href=?]", "https://acme.example/coffee", text: "https://acme.example/coffee"

    websites = { bare => "nike.com", unsafe => "javascript:alert('site')", malformed => "https://rexona .example" }
    websites.each do |brand_recording, website|
      get brands.brand_path(brand_recording)

      assert_includes page_text, website
      assert_select "a", text: website, count: 0
    end
  end

  test "the logo shows on the brand page and in the list, and a viewer can load it" do
    nike = record_brand(@folder, "Nike")
    sign_in @viewer
    get brands.brand_path(nike)

    assert_select "h1", text: "Brand"
    assert_select "img", count: 0
    assert_select "input[type=file]", count: 0

    sign_in @owner
    patch brands.brand_logo_path(nike), params: {
      logo: Rack::Test::UploadedFile.new(StringIO.new("nike-bytes"), "image/png", original_filename: "nike.png")
    }
    logo_id = RecordingStudio::Recording.where(parent_recording: nike,
                                               recordable_type: "RecordingStudioAttachable::Attachment").sole.id
    logo_src = "/recording_studio_attachable/attachments/#{logo_id}/file"

    sign_in @viewer
    get brands.brand_path(nike)

    assert_select "img[src=?]", logo_src
    assert_select "input[type=file]", count: 0

    get brands.edit_brand_path(nike)
    assert_response :forbidden

    sign_in @owner
    get brands.edit_brand_path(nike)

    assert_select "button", text: "Change logo", count: 1
    assert_select "input[type=file][name=logo]", count: 1

    sign_in @viewer
    get brands.recording_brands_path(@folder)

    assert_select "li img[src=?]", logo_src

    get logo_src

    assert_response :success
    assert_equal "nike-bytes", response.body
  end

  test "screens talk about brands, never recordings or mounts" do
    taylor = record_brand(@workspace, "Taylor Swift") { |brand| brand.tagline = "The Eras Tour" }
    nike = record_brand(@folder, "Nike")
    empty = owned_workspace("Empty Workspace")
    crowded = owned_workspace("Crowded Workspace")
    with_brand_options(Workspace, allows: :many) do
      record_brand(crowded, "Dove")
      record_brand(crowded, "Acme Coffee")
    end
    sign_in @owner

    texts = [
      brands.recording_brands_path(empty),
      brands.recording_brands_path(@workspace),
      brands.recording_brands_path(crowded),
      brands.recording_brands_path(@folder),
      brands.new_recording_brand_path(@folder),
      brands.brand_path(nike),
      brands.edit_brand_path(taylor)
    ].map do |path|
      get path
      assert_response :success
      page_text
    end

    texts.each do |text|
      assert_match(/brand/i, text)
      refute_match(/recording|recordable|mount/i, text)
    end
  end

  private

  def brands
    recording_studio_brands
  end

  def create_user(prefix)
    User.create!(email: "#{prefix}-#{SecureRandom.hex(4)}@example.com", password: "Password123!")
  end

  def owned_workspace(name)
    workspace = RecordingStudio.root_recording_for(Workspace.create!(name:))
    access = RecordingStudioAccessible.bootstrap_owner_access!(recording: workspace, actor: @owner)
    raise access.error if access.failure?

    workspace
  end

  def record_brand(parent, name)
    parent.record(RecordingStudioBrands::Brand, parent_recording: parent, actor: @owner) do |brand|
      brand.name = name
      yield brand if block_given?
    end
  end

  def brand_recordings_under(parent)
    RecordingStudio::Recording.where(parent_recording: parent, recordable_type: "RecordingStudioBrands::Brand")
                              .order(:created_at, :id)
  end

  def brand_names_under(parent)
    brand_recordings_under(parent).map { |recording| recording.recordable.name }
  end

  def list_links
    css_select("ul[role=list] > li > a")
  end

  def page_text
    document = Nokogiri::HTML(response.body)
    document.css("script, style, template").each(&:remove)
    document.at("body").text.squish
  end

  def with_brand_options(model, **options)
    original = RecordingStudio.capability_options(:brand, for: model)
    RecordingStudio.set_capability_options(:brand, on: model, **options)
    yield
  ensure
    RecordingStudio.set_capability_options(:brand, on: model, **original)
  end
end
