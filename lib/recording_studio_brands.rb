# frozen_string_literal: true

require "recording_studio"
require "recording_studio_brands/version"
require "recording_studio_brands/engine"
require "recording_studio_brands/configuration"

module RecordingStudioBrands
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end
