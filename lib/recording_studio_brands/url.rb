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

      candidate = raw.match?(/\A[a-z][a-z0-9+.-]*:/i) ? raw : "https://#{raw}"
      uri = URI.parse(candidate)
      return raw unless uri.is_a?(URI::HTTP) && uri.host.present?

      uri.scheme = uri.scheme.downcase
      uri.host = uri.host.downcase
      uri.port = nil if uri.port == uri.default_port
      uri.fragment = nil
      uri.path = uri.path.to_s.sub(%r{/\z}, "")
      uri.path = "" if uri.path == "/"
      uri.query = uri.query.presence

      uri.to_s
    rescue URI::InvalidURIError
      raw.presence
    end
  end
end
