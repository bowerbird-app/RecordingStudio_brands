# frozen_string_literal: true

return unless defined?(RecordingStudioApi)

RecordingStudioApi.configure do |config|
  if Rails.env.test?
    config.rate_limit_oauth_enabled = false
    config.rate_limit_api_enabled = false
    config.rate_limit_api_pre_auth_enabled = false
    config.api_management_authorization_required = false
  end
end
