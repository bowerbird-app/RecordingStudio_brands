# frozen_string_literal: true

require "uri"

module RecordingStudioBrands
  # Website URL normalization for Brand#website_url.
  #
  # When RecordingStudioPublications::Url is loaded (Phase B hosts that still
  # ship both gems), this delegates so catalogue matching stays identical.
  # Otherwise brands applies the rules below (https when missing, downcased
  # scheme/host, strip default port, trailing slash, and fragment).
  #
  # Private RecordingStudio_publications was still unreadable here, so byte-
  # for-byte parity with pubs could not be confirmed. Re-check pubs
  # Url.normalize before catalogue cutover.
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
