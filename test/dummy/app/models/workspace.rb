class Workspace < ApplicationRecord
  recording_studio_recordable label: "Workspace", root: true
  include RecordingStudio::Capabilities::Brand.to(allows: :many)
  RecordingStudio.enable_capability(:accessible, on: self) if defined?(RecordingStudioAccessible)
  RecordingStudio.enable_capability(:api_access_point, on: self) if defined?(RecordingStudioApi)
end
