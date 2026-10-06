# frozen_string_literal: true

RecordingStudio.configure do |config|
  # Registered delegated_type recordables (strings or classes).
  # Attachable 0.7 registers its Attachment type only after core validates
  # capability children at boot, so any app that bundles Attachable lists it.
  config.recordable_types = [
    "Workspace",
    "Folder",
    "Page",
    "RecordingStudioBrands::Brand",
    "RecordingStudioAttachable::Attachment"
  ]

  # Require each configured ActiveRecord type to call recording_studio_recordable.
  config.require_recordable_declarations = true

  # Shown in the shared default layout title fallback.
  config.app_name = "Brands" if config.respond_to?(:app_name=)

  # Actor resolver for events when no actor is explicitly supplied
  config.actor = -> { Current.actor }

  # Emit ActiveSupport::Notifications events
  config.event_notifications_enabled = true

  # Idempotency behavior for log_event!
  config.idempotency_mode = :return_existing # or :raise

  # Recordable duplication strategy for revisions
  config.recordable_dup_strategy = :dup
end
