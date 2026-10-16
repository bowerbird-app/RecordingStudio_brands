# frozen_string_literal: true

require "uri"

module RecordingStudioBrands
  # Website URL normalization for Brand#website_url.
  #
  # Matches RecordingStudioPublications::Url.normalize (same TRACKING_* lists,
  # parse rule, canonicalize, normalized_path, cleaned_query, tracking_param?).
  # When publications is loaded, this delegates so both gems stay identical.
  module Url
    TRACKING_PARAM_PREFIXES = %w[utm_].freeze
    TRACKING_PARAMS = %w[fbclid gclid gbraid wbraid mc_cid mc_eid _ga _gl igshid si].freeze

    module_function

    def normalize(value)
      if defined?(::RecordingStudioPublications::Url) &&
         ::RecordingStudioPublications::Url.respond_to?(:normalize)
        return ::RecordingStudioPublications::Url.normalize(value)
      end

      normalize_locally(value)
    end

    def normalize_locally(value)
      text = value.to_s.strip
      return if text.empty?

      uri = parse(text)
      return text if uri.nil? || uri.host.nil?

      canonicalize(uri).to_s
    rescue URI::InvalidURIError
      text
    end
    module_function :normalize_locally

    def parse(text)
      uri = URI.parse(text)
      return uri unless uri.scheme.nil? && uri.host.nil? && text.include?(".")

      URI.parse("https://#{text}")
    end
    module_function :parse

    def canonicalize(uri)
      uri.fragment = nil
      uri.host = uri.host.downcase
      uri.scheme = "https" if uri.scheme == "http"
      uri.query = cleaned_query(uri.query)
      uri.path = normalized_path(uri.path)
      uri
    end
    module_function :canonicalize

    def normalized_path(path)
      trimmed = path.to_s.sub(%r{/\z}, "")
      trimmed.empty? ? "/" : trimmed
    end
    module_function :normalized_path

    def cleaned_query(query)
      return if query.nil? || query.empty?

      params = URI.decode_www_form(query).reject { |key, _value| tracking_param?(key) }
      return if params.empty?

      URI.encode_www_form(params)
    end
    module_function :cleaned_query

    def tracking_param?(key)
      name = key.to_s.downcase
      TRACKING_PARAMS.include?(name) || TRACKING_PARAM_PREFIXES.any? { |prefix| name.start_with?(prefix) }
    end
    module_function :tracking_param?
  end
end
