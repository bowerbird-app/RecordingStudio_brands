# frozen_string_literal: true

require "test_helper"

class UrlNormalizeTest < Minitest::Test
  def test_blank_becomes_nil
    assert_nil RecordingStudioBrands::Url.normalize(nil)
    assert_nil RecordingStudioBrands::Url.normalize("")
    assert_nil RecordingStudioBrands::Url.normalize("   ")
  end

  def test_adds_https_when_scheme_missing
    assert_equal "https://example.com", RecordingStudioBrands::Url.normalize("example.com")
  end

  def test_downcases_scheme_and_host
    assert_equal "https://example.com/path",
                 RecordingStudioBrands::Url.normalize("HTTPS://Example.COM/path")
  end

  def test_strips_trailing_slash_and_fragment
    assert_equal "https://example.com/path",
                 RecordingStudioBrands::Url.normalize("https://example.com/path/#section")
  end

  def test_keeps_unparseable_stripped_string
    assert_equal "not a url ::", RecordingStudioBrands::Url.normalize("  not a url ::  ")
  end
end
