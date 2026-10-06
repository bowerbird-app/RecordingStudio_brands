# frozen_string_literal: true

require "test_helper"

class BrandMountsTest < ActiveSupport::TestCase
  setup do
    @actor = User.create!(email: "brand-mounts-#{SecureRandom.hex(4)}@example.com", password: "Password123!")
    @workspace = RecordingStudio.root_recording_for(Workspace.create!(name: "Brand Workspace"))
    @folder = @workspace.record(Folder, actor: @actor) { |folder| folder.name = "Campaigns" }
    @page = @workspace.record(Page, actor: @actor) { |page| page.title = "Press" }
  end

  test "a workspace holds many brands" do
    record_brand(@workspace, "Taylor Swift")
    record_brand(@workspace, "Dove")

    assert_equal [ "Taylor Swift", "Dove" ], brand_names_under(@workspace)
    assert_kind_of RecordingStudioBrands::Mount::Many, RecordingStudioBrands::Mount.for(@workspace)
  end

  test "a second brand under a one-brand workspace raises and records nothing" do
    with_brand_options(Workspace, allows: :one) do
      record_brand(@workspace, "Taylor Swift")

      error = assert_no_difference -> { RecordingStudioBrands::Brand.count } do
        assert_raises(RecordingStudioBrands::BrandLimitReached) { record_brand(@workspace, "Taylor's Version") }
      end

      assert_equal "Workspace allows one brand and already has one. Revise that brand instead.", error.message
      assert_equal [ "Taylor Swift" ], brand_names_under(@workspace)
    end
  end

  test "a direct Recording.create! of a second one-brand workspace brand raises" do
    with_brand_options(Workspace, allows: :one) do
      record_brand(@workspace, "Taylor Swift")
      second_brand = RecordingStudioBrands::Brand.create!(name: "Taylor's Version")

      assert_raises(RecordingStudioBrands::BrandLimitReached) do
        RecordingStudio::Recording.create!(parent_recording: @workspace, recordable: second_brand)
      end

      assert_equal [ "Taylor Swift" ], brand_names_under(@workspace)
    end
  end

  test "a trashed brand still fills a one-brand workspace" do
    with_brand_options(Workspace, allows: :one) do
      record_brand(@workspace, "Taylor Swift").update!(trashed_at: Time.current)

      assert_raises(RecordingStudioBrands::BrandLimitReached) { record_brand(@workspace, "Taylor's Version") }
      assert_equal [ "Taylor Swift" ], brand_names_under(@workspace)
    end
  end

  test "revise and revert keep the workspace brand on one recording" do
    brand_recording = record_brand(@workspace, "Taylor Swift")
    original_brand = brand_recording.recordable

    revised = @workspace.revise(brand_recording, actor: @actor) { |brand| brand.tagline = "The Eras Tour" }

    assert_equal brand_recording.id, revised.id
    assert_equal "The Eras Tour", RecordingStudio::Recording.find(brand_recording.id).recordable.tagline

    reverted = @workspace.revert(brand_recording, to_recordable: original_brand, actor: @actor)

    assert_equal brand_recording.id, reverted.id
    assert_nil RecordingStudio::Recording.find(brand_recording.id).recordable.tagline
    assert_equal [ "Taylor Swift" ], brand_names_under(@workspace)
  end

  test "a folder holds many brands" do
    [ "Nike", "Dove", "Acme Coffee" ].each { |name| record_brand(@folder, name) }

    assert_equal [ "Nike", "Dove", "Acme Coffee" ], brand_names_under(@folder)
    assert_equal [ "Nike", "Dove", "Acme Coffee" ],
                 RecordingStudioBrands::Mount.for(@folder).brand_recordings.map { |recording| recording.recordable.name }
  end

  test "a page refuses the brand a folder accepts" do
    error = assert_raises(RecordingStudio::InvalidParent) { record_brand(@page, "Nike") }
    record_brand(@folder, "Nike")

    assert_equal "RecordingStudioBrands::Brand cannot be recorded under Page", error.message
    assert_equal [], brand_names_under(@page)
    assert_equal [ "Nike" ], brand_names_under(@folder)
    assert_nil RecordingStudioBrands::Mount.for(@page)
  end

  test "a brand cannot be a root" do
    brand = RecordingStudioBrands::Brand.create!(name: "Nike")

    assert_raises(RecordingStudio::RootNotAllowed) { RecordingStudio.root_recording_for(brand) }
    assert_raises(ActiveRecord::RecordInvalid) { RecordingStudio::Recording.create!(recordable: brand) }
    assert_equal 0, RecordingStudio::Recording.where(recordable: brand).count
  end

  test "a brand needs a name and stores blank fields as nil" do
    assert_raises(ActiveRecord::RecordInvalid) { record_brand(@folder, "   ") }

    brand_recording = @folder.record(RecordingStudioBrands::Brand, parent_recording: @folder, actor: @actor) do |brand|
      brand.name = "  Nike  "
      brand.tagline = "   "
    end

    brand = RecordingStudio::Recording.find(brand_recording.id).recordable
    assert_equal "Nike", brand.name
    assert_nil brand.tagline
    assert_equal [ "Nike" ], brand_names_under(@folder)
  end

  test "the brand capability lists the type that hosts record" do
    child_type = RecordingStudio.capability_child_recordables_for(:brand).sole
    brand_recording = record_brand(@folder, "Nike")

    assert_equal child_type, brand_recording.recordable_type
    assert_equal [ "Folder", "Workspace" ], RecordingStudio.capability_parent_types_for(child_type)
  end

  test "brands need no company or person model" do
    record_brand(@workspace, "Taylor Swift")
    record_brand(@folder, "Nike")

    assert_equal [ "Taylor Swift" ], brand_names_under(@workspace)
    assert_equal [ "Nike" ], brand_names_under(@folder)
    [ Object, RecordingStudioBrands ].each do |namespace|
      refute namespace.const_defined?(:Company, false), "#{namespace} defines Company"
      refute namespace.const_defined?(:Person, false), "#{namespace} defines Person"
    end
  end

  test "a parent type must allow one brand or many" do
    error = assert_raises(ArgumentError) { RecordingStudio::Capabilities::Brand.to(allows: :few) }

    assert_equal "Brand mounts need allows: :one or allows: :many, got :few", error.message
  end

  test "a parent type enabled without allows fails on the first brand read or write" do
    with_brand_options(Workspace) do
      assert_raises(ArgumentError) { RecordingStudioBrands::Mount.for(@workspace) }
      assert_raises(ArgumentError) { record_brand(@workspace, "Taylor Swift") }
    end

    assert_equal [], brand_names_under(@workspace)
  end

  test "a workspace left with two brands refuses to pick one and refuses a third" do
    record_brand(@workspace, "Nike")
    record_brand(@workspace, "Dove")

    with_brand_options(Workspace, allows: :one) do
      error = assert_raises(RecordingStudioBrands::MountConflict) do
        RecordingStudioBrands::Mount.for(@workspace).brand_recording
      end

      assert_equal "Workspace allows one brand but has several. Remove the extra brands before reading the brand.",
                   error.message
      assert_raises(RecordingStudioBrands::BrandLimitReached) { record_brand(@workspace, "Acme Coffee") }
    end

    assert_equal [ "Nike", "Dove" ], brand_names_under(@workspace)
  end

  private

  def record_brand(parent, name)
    parent.record(RecordingStudioBrands::Brand, parent_recording: parent, actor: @actor) { |brand| brand.name = name }
  end

  def brand_names_under(parent)
    RecordingStudio::Recording.where(parent_recording: parent, recordable_type: "RecordingStudioBrands::Brand")
                              .order(:created_at, :id)
                              .map { |recording| recording.recordable.name }
  end

  def with_brand_options(model, **options)
    original = RecordingStudio.capability_options(:brand, for: model)
    RecordingStudio.set_capability_options(:brand, on: model, **options)
    yield
  ensure
    RecordingStudio.set_capability_options(:brand, on: model, **original)
  end
end
