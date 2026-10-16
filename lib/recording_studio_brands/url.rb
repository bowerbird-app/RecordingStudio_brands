# frozen_string_literal: true

require "uri"

module RecordingStudioBrands
  # Website URL normalization for Brand#website_url.
  #
  # Follows RecordingStudioPublications::Url.normalize (http→https, strip
  # TRACKING_PARAMS / TRACKING_PARAM_PREFIXES, empty path `/`, keep explicit
  # non-default ports, leave dotless hosts exactly as typed, normalize
  # non-HTTP schemes that have a host). When publications is loaded, this
  # delegates so both gems stay aligned.
  module Url
    # Exact names publications strips (plus utm_ via TRACKING_PARAM_PREFIXES).
    TRACKING_PARAMS = %w[
      fbclid
      gclid
      gbraid
      wbraid
      mc_cid
      mc_eid
      _ga
      _gl
      igshid
      si
    ].freeze

    TRACKING_PARAM_PREFIXES = %w[
      utm_
    ].freeze

    module_function

    def normalize(value)
      if defined?(::RecordingStudioPublications::Url) &&
         ::RecordingStudioPublications::Url.respond_to?(:normalize)
        return ::RecordingStudioPublications::Url.normalize(value)
      end

      raw = value.is_a?(String) ? value.strip : value.to_s.strip
      return if raw.blank?

      normalize_uri(raw) || raw.presence
    end

    def normalize_uri(raw)
      candidate = raw.match?(/\A[a-z][a-z0-9+.-]*:/i) ? raw : "https://#{raw}"
      uri = URI.parse(candidate)
      return unless uri.host.present?

      # Publications leaves dotless hosts (localhost, intranet names) exactly
      # as typed — no https:// prefix, no case/path rewrite.
      return raw unless uri.host.include?(".")

      apply_uri_normalize(uri)
    rescue URI::InvalidURIError
      nil
    end
    module_function :normalize_uri

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

    def tracking_param?(key)
      name = key.to_s.downcase
      TRACKING_PARAMS.include?(name) ||
        TRACKING_PARAM_PREFIXES.any? { |prefix| name.start_with?(prefix) }
    end
    module_function :tracking_param?

    def strip_tracking_query!(uri)
      return if uri.query.blank?

      kept = URI.decode_www_form(uri.query).reject { |key, _value| tracking_param?(key) }
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
