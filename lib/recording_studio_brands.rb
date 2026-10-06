# frozen_string_literal: true

require "recording_studio"
require "recording_studio_accessible"
require "recording_studio_attachable"
require "recording_studio_brands/version"
require "recording_studio_brands/engine"
require "recording_studio_brands/configuration"
require "recording_studio_brands/mount"
require "recording_studio_brands/logo"

module RecordingStudioBrands
  # A string because the capability registers at require time, before the
  # Brand model can autoload. Hosts list the same string in recordable_types.
  BRAND_TYPE = "RecordingStudioBrands::Brand"

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end

require "recording_studio/capabilities/brand"
