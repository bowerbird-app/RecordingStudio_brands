# frozen_string_literal: true

require "test_helper"

class UrlNormalizeTest < Minitest::Test
  def test_blank_becomes_nil
    assert_nil RecordingStudioBrands::Url.normalize(nil)
    assert_nil RecordingStudioBrands::Url.normalize("")
    assert_nil RecordingStudioBrands::Url.normalize("   ")
  end

  def test_adds_https_and_trailing_slash_for_host_only
    assert_equal "https://example.com/", RecordingStudioBrands::Url.normalize("example.com")
  end

  def test_upgrades_http_to_https
    assert_equal "https://example.com/", RecordingStudioBrands::Url.normalize("http://example.com")
  end

  def test_downcases_scheme_and_host
    assert_equal "https://example.com/path",
                 RecordingStudioBrands::Url.normalize("HTTPS://Example.COM/path")
  end

  def test_strips_trailing_slash_on_non_empty_path_and_fragment
    assert_equal "https://example.com/path",
                 RecordingStudioBrands::Url.normalize("https://example.com/path/#section")
  end

  def test_strips_tracking_query_params
    assert_equal "https://example.com/?keep=1",
                 RecordingStudioBrands::Url.normalize(
                   "https://example.com/?utm_source=x&fbclid=y&gclid=z&keep=1"
                 )
  end

  def test_keeps_non_default_port
    assert_equal "https://example.com:8080/",
                 RecordingStudioBrands::Url.normalize("http://example.com:8080")
  end

  def test_leaves_dotless_hosts
    assert_equal "https://localhost/", RecordingStudioBrands::Url.normalize("localhost")
  end

  def test_keeps_unparseable_stripped_string
    assert_equal "not a url ::", RecordingStudioBrands::Url.normalize("  not a url ::  ")
  end
end
