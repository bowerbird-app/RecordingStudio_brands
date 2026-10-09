# frozen_string_literal: true

module RecordingStudioBrands
  module BrandsHelper
    # Brand fields are free text. FlatPack::Link raises on an unsafe href, and a
    # bare "nike.com" would resolve inside this app, so a value that is not a
    # safe absolute address renders as plain text.
    def brand_contact_rows(brand)
      [
        [t("recording_studio.brands.labels.website"), brand.website_url, brand_web_href(brand.website_url)],
        [t("recording_studio.brands.labels.email"), brand.email, "mailto:#{brand.email}"],
        [t("recording_studio.brands.labels.phone"), brand.phone, "tel:#{brand.phone}"]
      ].filter_map do |label, text, href|
        [label, text, FlatPack::AttributeSanitizer.sanitize_url(href)] if text
      end
    end

    private

    def brand_web_href(url)
      uri = URI.parse(url.to_s)
      url if uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      nil
    end
  end
end
