# frozen_string_literal: true

require "test_helper"
require "recording_studio_api"

class ApiTest < Minitest::Test
  def setup
    skip unless RecordingStudioBrands::Api.recording_studio_api_available?
  end

  def test_register_exposes_brand_without_destroy
    RecordingStudioBrands::Api.register!
    RecordingStudioBrands::Api.register!

    type = RecordingStudioBrands::BRAND_TYPE
    registration = RecordingStudioApi.recordable_registration_for(type)

    assert_equal %i[create index show update], registration.operations
    assert_equal RecordingStudioBrands::Api.writable_attributes.map(&:to_s).sort, registration.writable_attributes
    assert_equal RecordingStudioBrands::Api.output_keys.map(&:to_s), registration.output_keys
    assert_equal RecordingStudioBrands::Api::SERIALIZER, registration.serializer
    assert_equal RecordingStudioBrands::Api::Index, RecordingStudioApi.resource_handler(type, :index)
    assert_equal RecordingStudioBrands::Api::Create, RecordingStudioApi.resource_handler(type, :create)
    assert_equal RecordingStudioBrands::Api::Update, RecordingStudioApi.resource_handler(type, :update)
    assert_nil RecordingStudioApi.resource_handler(type, :destroy)
  end
end
