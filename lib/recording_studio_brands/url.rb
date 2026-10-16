# frozen_string_literal: true

require "uri"

module RecordingStudioBrands
  # Website URL normalization for Brand#website_url.
  #
  # Matches RecordingStudioPublications::Url.normalize: upgrade http to https,
  # strip utm_*/fbclid/gclid, give an empty path a trailing "/", keep an explicit
  # default port on the URI, and leave dotless hosts alone. When publications is
  # loaded, this delegates so both gems stay identical.
  module Url
    TRACKING_QUERY_KEY = /\A(?:utm_.*|fbclid|gclid)\z/i
    private_constant :TRACKING_QUERY_KEY

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
      uri.scheme = "https" if uri.scheme.to_s.casecmp("http").zero?
      uri.scheme = uri.scheme.downcase
      uri.host = uri.host.downcase
      uri.fragment = nil
      strip_tracking_query!(uri)
      ensure_path!(uri)
      uri.to_s
    end
    module_function :apply_uri_normalize

    def strip_tracking_query!(uri)
      return if uri.query.blank?

      kept = URI.decode_www_form(uri.query).reject { |key, _value| key.to_s.match?(TRACKING_QUERY_KEY) }
      uri.query = kept.empty? ? nil : URI.encode_www_form(kept)
    end
    module_function :strip_tracking_query!

    def ensure_path!(uri)
      path = uri.path.to_s
      if path.blank?
        uri.path = "/"
        return
      end

      uri.path = path == "/" ? "/" : path.sub(%r{/\z}, "")
    end
    module_function :ensure_path!
  end
end
