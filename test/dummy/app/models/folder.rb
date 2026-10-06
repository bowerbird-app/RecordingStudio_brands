class Folder < ApplicationRecord
  recording_studio_recordable label: "Folder", root: false, allowed_parent_types: [ "Workspace", "Folder" ]
  include RecordingStudio::Capabilities::Brand.to(allows: :many)
end
