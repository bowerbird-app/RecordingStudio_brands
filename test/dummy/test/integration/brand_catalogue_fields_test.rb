# frozen_string_literal: true

require "test_helper"

class BrandCatalogueFieldsTest < ActiveSupport::TestCase
  setup do
    @actor = User.create!(email: "catalogue-#{SecureRandom.hex(4)}@example.com", password: "Password123!")
    @workspace = RecordingStudio.root_recording_for(Workspace.create!(name: "Catalogue #{SecureRandom.hex(4)}"))
    @other = RecordingStudio.root_recording_for(Workspace.create!(name: "Other #{SecureRandom.hex(4)}"))
  end

  test "slug is assigned from the name and stays unique among current brands under a parent" do
    first = record_brand(@workspace, name: "Acme Coffee")
    assert_equal "acme-coffee", first.recordable.slug
    assert first.recordable.active?
    assert_equal({}, first.recordable.metadata)

    error = assert_raises(ActiveRecord::RecordInvalid) do
      record_brand(@workspace, name: "Acme Other", slug: "acme-coffee")
    end
    assert_includes error.record.errors[:slug], "has already been taken"

    other = record_brand(@other, name: "Acme Other", slug: "acme-coffee")
    assert_equal "acme-coffee", other.recordable.slug
  end

  test "website_url is normalized on assign" do
    recording = record_brand(@workspace, name: "Nike", website_url: "WWW.NIKE.COM/path/")

    assert_equal "https://www.nike.com/path", recording.recordable.website_url
  end

  test "identity finders resolve current brands by slug name and website" do
    recording = record_brand(
      @workspace,
      name: "Taylor Swift",
      slug: "taylor-swift",
      website_url: "https://www.taylorswift.com"
    )

    assert_equal recording.recordable.id,
                 RecordingStudioBrands::Identity.find_brand(slug: "taylor-swift", parent_recording: @workspace).id
    assert_equal recording.id,
                 RecordingStudioBrands::Identity.find_brand_recording(name: "taylor swift",
                                                                     parent_recording: @workspace).id
    assert_equal recording.recordable.id,
                 RecordingStudioBrands::Identity.find_brand(
                   website_url: "www.taylorswift.com",
                   parent_recording: @workspace
                 ).id
  end

  test "identity finders skip historical revise snapshots" do
    recording = record_brand(@workspace, name: "Dove", slug: "dove")
    original_id = recording.recordable.id

    @workspace.revise(recording, actor: @actor) do |brand|
      brand.parent_recording_id_for_slug = @workspace.id
      brand.slug_uniqueness_except_recording_id = recording.id
      brand.tagline = "Real beauty"
    end

    found = RecordingStudioBrands::Identity.find_brand(slug: "dove", parent_recording: @workspace)

    refute_equal original_id, found.id
    assert_equal "Real beauty", found.tagline
    assert RecordingStudioBrands::Brand.exists?(original_id)
  end

  test "active and metadata round-trip through revise" do
    recording = record_brand(@workspace, name: "Quiet Brand", active: true, metadata: { "source" => "seed" })

    revised = @workspace.revise(recording, actor: @actor) do |brand|
      brand.parent_recording_id_for_slug = @workspace.id
      brand.slug_uniqueness_except_recording_id = recording.id
      brand.active = false
      brand.metadata = { "source" => "admin", "note" => "paused" }
    end

    brand = revised.reload.recordable
    refute brand.active?
    assert_equal({ "source" => "admin", "note" => "paused" }, brand.metadata)
  end

  test "slug uniqueness adds a validation error when parent cannot be derived" do
    brand = RecordingStudioBrands::Brand.new(name: "Orphan", slug: "orphan")

    refute brand.valid?
    assert_includes brand.errors[:slug], "needs a parent recording"
  end

  test "metadata that is not a hash uses the ActiveModel error key" do
    brand = RecordingStudioBrands::Brand.new(name: "Meta", slug: "meta", metadata: "nope")
    brand.parent_recording_id_for_slug = @workspace.id

    refute brand.valid?
    assert_includes brand.errors[:metadata], "must be a JSON object"
  end

  private

  def record_brand(parent, **attributes)
    parent.record(RecordingStudioBrands::Brand, parent_recording: parent, actor: @actor) do |brand|
      brand.parent_recording_id_for_slug = parent.id
      brand.assign_attributes(attributes)
    end
  end
end
