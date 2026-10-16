# frozen_string_literal: true

require "test_helper"

class SlugParentHookTest < Minitest::Test
  FakeBrand = Struct.new(:parent_recording_id_for_slug, :slug_uniqueness_except_recording_id)
  FakeRecording = Struct.new(:id, :parent_recording)

  def test_apply_slug_parent_sets_parent_and_except_recording_ids
    brand = FakeBrand.new(nil, nil)
    parent = Struct.new(:id).new("parent-1")
    recording = FakeRecording.new("recording-1", parent)

    RecordingStudioBrands::SlugParentHook.apply_slug_parent(
      brand,
      parent_recording: parent,
      recording: recording
    )

    assert_equal "parent-1", brand.parent_recording_id_for_slug
    assert_equal "recording-1", brand.slug_uniqueness_except_recording_id
  end

  def test_apply_slug_parent_keeps_existing_values
    brand = FakeBrand.new("already-parent", "already-recording")
    parent = Struct.new(:id).new("other-parent")
    recording = FakeRecording.new("other-recording", parent)

    RecordingStudioBrands::SlugParentHook.apply_slug_parent(
      brand,
      parent_recording: parent,
      recording: recording
    )

    assert_equal "already-parent", brand.parent_recording_id_for_slug
    assert_equal "already-recording", brand.slug_uniqueness_except_recording_id
  end

  def test_assign_slug_parent_ignores_non_brands
    payload = { recordable: Object.new, parent_recording: Struct.new(:id).new("parent-1") }

    RecordingStudioBrands::SlugParentHook.assign_slug_parent(payload)
  end
end
