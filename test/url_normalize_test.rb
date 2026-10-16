# frozen_string_literal: true

require "test_helper"

# Brands Url.normalize suite. Cases mirror publications Url expectations
# (TRACKING_PARAMS / TRACKING_PARAM_PREFIXES, dotless hosts, ftp:// with host).
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

  def test_keeps_root_path_slash
    assert_equal "https://example.com/",
                 RecordingStudioBrands::Url.normalize("https://example.com")
  end

  def test_strips_utm_prefix_tracking_params
    assert_equal "https://example.com/?keep=1",
                 RecordingStudioBrands::Url.normalize(
                   "https://example.com/?utm_source=x&utm_medium=y&keep=1"
                 )
  end

  def test_strips_all_tracking_params
    query = RecordingStudioBrands::Url::TRACKING_PARAMS.map { |key| "#{key}=1" }.join("&")
    assert_equal "https://example.com/?keep=1",
                 RecordingStudioBrands::Url.normalize("https://example.com/?#{query}&keep=1")
  end

  def test_tracking_params_constant_lists_publication_names
    assert_equal %w[fbclid gclid gbraid wbraid mc_cid mc_eid _ga _gl igshid si],
                 RecordingStudioBrands::Url::TRACKING_PARAMS
    assert_equal %w[utm_], RecordingStudioBrands::Url::TRACKING_PARAM_PREFIXES
  end

  def test_keeps_non_default_port
    assert_equal "https://example.com:8080/",
                 RecordingStudioBrands::Url.normalize("http://example.com:8080")
  end

  def test_leaves_dotless_hosts_exactly_as_typed
    assert_equal "localhost", RecordingStudioBrands::Url.normalize("localhost")
    assert_equal "http://localhost/path",
                 RecordingStudioBrands::Url.normalize("http://localhost/path")
  end

  def test_normalizes_non_http_schemes_with_a_host
    assert_equal "ftp://files.example.com/dir?keep=1",
                 RecordingStudioBrands::Url.normalize(
                   "ftp://Files.Example.COM/dir/?utm_source=x&gbraid=1&keep=1"
                 )
  end

  def test_keeps_unparseable_stripped_string
    assert_equal "not a url ::", RecordingStudioBrands::Url.normalize("  not a url ::  ")
  end

  def test_tracking_param_helper
    assert RecordingStudioBrands::Url.tracking_param?("utm_campaign")
    assert RecordingStudioBrands::Url.tracking_param?("GBRAID")
    refute RecordingStudioBrands::Url.tracking_param?("keep")
  end
end
