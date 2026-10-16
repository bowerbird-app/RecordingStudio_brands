# frozen_string_literal: true

class AdminRoot < ApplicationRecord
  include RecordingStudioAdmin::AllowsAdminSections

  recording_studio_recordable label: "Admin", root: true

  include RecordingStudio::Capabilities::Brand.to(allows: :many)
  RecordingStudio.enable_capability(:accessible, on: self) if defined?(RecordingStudioAccessible)

  recording_studio_admin_sections do
    section :root
    section :brands
  end
end
