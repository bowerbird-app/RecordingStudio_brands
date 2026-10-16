# frozen_string_literal: true

require "uri"

module RecordingStudioBrands
  # Website URL normalization for Brand#website_url.
  #
  # When RecordingStudioPublications::Url is loaded (Phase B hosts that still
  # ship both gems), this delegates so catalogue matching stays identical.
  # Otherwise brands applies the equivalent below. The private publications
  # source was not readable from this environment; verify against pubs
  # Url.normalize before cutover if behavior must match byte-for-byte.
  module Url
    module_function

    def normalize(value)
      if defined?(::RecordingStudioPublications::Url) &&
         ::RecordingStudioPublications::Url.respond_to?(:normalize)
        return ::RecordingStudioPublications::Url.normalize(value)
      end

      raw = value.is_a?(String) ? value.strip : value.to_s.strip
      return if raw.blank?

      normalize_http_url(raw) || raw.presence
    end

    def normalize_http_url(raw)
      candidate = raw.match?(/\A[a-z][a-z0-9+.-]*:/i) ? raw : "https://#{raw}"
      uri = URI.parse(candidate)
      return unless uri.is_a?(URI::HTTP) && uri.host.present?

      apply_uri_normalize(uri)
    rescue URI::InvalidURIError
      nil
    end
    module_function :normalize_http_url

    def apply_uri_normalize(uri)
      uri.scheme = uri.scheme.downcase
      uri.host = uri.host.downcase
      uri.port = nil if uri.port == uri.default_port
      uri.fragment = nil
      uri.query = uri.query.presence
      trim_uri_path!(uri)
      uri.to_s
    end
    module_function :apply_uri_normalize

    def trim_uri_path!(uri)
      path = uri.path.to_s.sub(%r{/\z}, "")
      uri.path = path == "/" ? "" : path
    end
    module_function :trim_uri_path!
  end
end
