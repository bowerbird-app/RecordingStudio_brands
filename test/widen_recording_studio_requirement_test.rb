# frozen_string_literal: true

require "test_helper"

class WidenRecordingStudioRequirementTest < Minitest::Test
  def test_widen_rewrites_pre_6_recording_studio_requirements
    source = File.read(File.expand_path("support/widen_recording_studio_requirement.rb", __dir__))

    assert_includes source, 'name.to_s == "recording_studio"'
    assert_includes source, '">= 6.3.0"'
  end
end
