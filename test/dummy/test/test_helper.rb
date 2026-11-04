# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

module TinyImageUpload
  PNG_BYTES = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
  ).freeze

  def png_bytes
    PNG_BYTES
  end

  def png_upload(filename)
    Rack::Test::UploadedFile.new(StringIO.new(png_bytes), "image/png", original_filename: filename)
  end
end

class ActionDispatch::IntegrationTest
  include TinyImageUpload
end
