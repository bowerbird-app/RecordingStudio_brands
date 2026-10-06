# frozen_string_literal: true

require "test_helper"

class BrandLogoTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  Logo = RecordingStudioBrands::Logo

  setup do
    @owner = create_user("logo-owner")
    @viewer = create_user("logo-viewer")
    @workspace = RecordingStudio.root_recording_for(Workspace.create!(name: "Logo Workspace"))
    owner_access = RecordingStudioAccessible.bootstrap_owner_access!(recording: @workspace, actor: @owner)
    raise owner_access.error if owner_access.failure?

    viewer_access = RecordingStudioAccessible.grant_access(
      recording: @workspace, actor: @viewer, role: :view, manager_actor: @owner
    )
    raise viewer_access.error if viewer_access.failure?

    @folder = @workspace.record(Folder, actor: @owner) { |folder| folder.name = "Campaigns" }
    @taylor = record_brand(@workspace, "Taylor Swift")
    @nike = record_brand(@folder, "Nike")
  end

  test "an editor uploads a logo onto a folder brand" do
    sign_in @owner

    patch logo_path(@nike), params: { logo: image_upload("nike.png", "nike-bytes") }

    assert_redirected_to recording_studio_brands.brand_path(@nike)
    assert_equal "Logo saved.", flash[:notice]
    logo = Logo.recording_for(@nike)
    assert_equal @nike.id, logo.parent_recording_id
    assert_equal [ "logo", "nike.png", "image/png" ],
                 [ logo.recordable.name, logo.recordable.original_filename, logo.recordable.content_type ]
    assert_equal "nike-bytes", logo.recordable.file.download
  end

  test "a logo for the workspace brand returns to the workspace brands screen" do
    sign_in @owner

    patch logo_path(@taylor), params: { logo: image_upload("taylor.png") }

    assert_redirected_to recording_studio_brands.recording_brands_path(@workspace)
    assert_equal "taylor.png", Logo.recording_for(@taylor).recordable.original_filename
  end

  test "a second upload replaces the file on the same logo" do
    sign_in @owner
    patch logo_path(@nike), params: { logo: image_upload("nike-old.png") }
    first_logo = Logo.recording_for(@nike)

    patch logo_path(@nike), params: { logo: image_upload("nike-new.png", "new-bytes") }

    logo = Logo.recording_for(@nike)
    assert_equal first_logo.id, logo.id
    assert_equal "new-bytes", logo.recordable.file.download
    assert_equal [ logo.id ], attachment_ids_under(@nike)
  end

  test "revising the brand keeps its logo" do
    sign_in @owner
    patch logo_path(@nike), params: { logo: image_upload("nike.png", "nike-bytes") }
    logo = Logo.recording_for(@nike)

    revised = @folder.revise(@nike, actor: @owner) { |brand| brand.tagline = "Just Do It" }

    assert_equal @nike.id, revised.id
    assert_equal "Just Do It", RecordingStudio::Recording.find(@nike.id).recordable.tagline
    assert_equal logo, Logo.recording_for(revised)
    assert_equal "nike-bytes", Logo.recording_for(revised).recordable.file.download
  end

  test "a file that is not an image saves no logo and keeps no upload" do
    sign_in @owner

    assert_no_difference -> { ActiveStorage::Blob.count } do
      patch logo_path(@nike), params: { logo: Rack::Test::UploadedFile.new(StringIO.new("notes"), "text/plain",
                                                                           original_filename: "notes.txt") }
    end

    assert_redirected_to recording_studio_brands.brand_path(@nike)
    assert_equal "The logo could not be saved. Choose an image file.", flash[:alert]
    assert_equal [], attachment_ids_under(@nike)
  end

  test "submitting without a file asks for an image" do
    sign_in @owner

    patch logo_path(@nike)

    assert_redirected_to recording_studio_brands.brand_path(@nike)
    assert_equal "The logo could not be saved. Choose an image file.", flash[:alert]
  end

  test "a viewer cannot change the logo and an owner can" do
    sign_in @viewer
    assert_no_difference -> { ActiveStorage::Blob.count } do
      patch logo_path(@nike), params: { logo: image_upload("viewer.png") }
    end
    assert_response :forbidden

    sign_in @owner
    patch logo_path(@nike), params: { logo: image_upload("owner.png") }

    assert_equal [ "owner.png" ], attachment_ids_under(@nike).map { |id| filename_of(id) }
  end

  test "a signed-out visitor is sent to sign in" do
    patch logo_path(@nike), params: { logo: image_upload("nike.png") }

    assert_redirected_to new_user_session_path
    assert_equal [], attachment_ids_under(@nike)
  end

  test "a recording that is not a brand has no logo to change" do
    sign_in @owner

    patch logo_path(@folder), params: { logo: image_upload("folder.png") }

    assert_response :not_found
    assert_equal [], attachment_ids_under(@folder)
  end

  test "the newest live image named logo is the logo" do
    older = attach(@nike, "logo", "older.png")
    newer = attach(@nike, "logo", "newer.png")
    attach(@nike, "cover", "cover.png")

    assert_equal newer, Logo.recording_for(@nike)

    newer.update!(trashed_at: Time.current)

    assert_equal older, Logo.recording_for(@nike)
  end

  test "a file named logo that is not an image is not the logo" do
    image = attach(@nike, "logo", "nike.png")
    with_brand_attachable_types([ "image/*", "application/pdf" ]) do
      attach(@nike, "logo", "nike.pdf", content_type: "application/pdf")
    end

    assert_equal image, Logo.recording_for(@nike)
  end

  test "logos for several brands load in one query" do
    dove = record_brand(@folder, "Dove")
    acme = record_brand(@folder, "Acme Coffee")
    nike_logo = attach(@nike, "logo", "nike.png")
    dove_logo = attach(dove, "logo", "dove.png")

    logos = assert_queries_count(1) { Logo.recordings_for([ @nike, dove, acme ]) }

    assert_equal({ @nike.id => nike_logo, dove.id => dove_logo }, logos)
  end

  private

  def create_user(prefix)
    User.create!(email: "#{prefix}-#{SecureRandom.hex(4)}@example.com", password: "Password123!")
  end

  def record_brand(parent, name)
    parent.record(RecordingStudioBrands::Brand, parent_recording: parent, actor: @owner) { |brand| brand.name = name }
  end

  def logo_path(brand_recording)
    recording_studio_brands.brand_logo_path(brand_recording)
  end

  def image_upload(filename, bytes = "image-bytes")
    Rack::Test::UploadedFile.new(StringIO.new(bytes), "image/png", original_filename: filename)
  end

  def attach(brand_recording, name, filename, content_type: "image/png")
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("#{name}-bytes"), filename:, content_type:)
    brand_recording.record_attachment_upload(signed_blob_id: blob.signed_id, name:, actor: @owner).tap do |recording|
      assert recording, "Attachable refused #{filename}"
    end
  end

  def attachment_ids_under(recording)
    RecordingStudio::Recording.where(parent_recording: recording, recordable_type: "RecordingStudioAttachable::Attachment")
                              .order(:created_at).ids
  end

  def filename_of(recording_id)
    RecordingStudio::Recording.find(recording_id).recordable.original_filename
  end

  def with_brand_attachable_types(types)
    original = RecordingStudio.capability_options(:attachable, for: RecordingStudioBrands::Brand)
    RecordingStudio.set_capability_options(:attachable, on: RecordingStudioBrands::Brand, allowed_content_types: types)
    yield
  ensure
    RecordingStudio.set_capability_options(:attachable, on: RecordingStudioBrands::Brand, **original)
  end
end
