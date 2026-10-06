RecordingStudioBrands install complete.

Next steps:

1. Review config/initializers/recording_studio_brands.rb and set any required options.
2. If you use environment-specific settings, create config/recording_studio_brands.yml.
3. Install Recording Studio Attachable, then install this engine's migrations with `bin/rails generate recording_studio_attachable:migrations` and `bin/rails generate recording_studio_brands:migrations`.
4. Apply the migrations with `bin/rails db:migrate`.
5. Run `bin/rails tailwindcss:build` if you use Tailwind CSS.
6. Mount routes are added at the configured mount path. Adjust auth, layout, and current actor integration to match your host app.
7. Keep strict recordable declarations enabled and add `recording_studio_recordable(...)` to every configured recordable before running `RecordingStudio.validate_recordable_declarations!`.
8. Add `"RecordingStudioBrands::Brand"` and `"RecordingStudioAttachable::Attachment"` to `config.recordable_types`.
9. On each parent that should hold brands, include `RecordingStudio::Capabilities::Brand.to(allows: :one)` or `allows: :many`. Brand does not name its parents. The parent chooses the limit.

```ruby
class Project < ApplicationRecord
  recording_studio_recordable label: "Project", root: false, allowed_parent_types: ["Workspace"]
  include RecordingStudio::Capabilities::Brand.to(allows: :many)
end
```

A one mount keeps a single brand. A many mount keeps a list. The limit is enforced when the brand recording is created, including requests that skip the screens.

Save a brand with the parent recording's `record` method and pass `parent_recording`. Revise with `revise`. The logo is an image attachment named `"logo"` on the brand recording. Use `record_attachment_upload` and `replace_attachment_file`. The screens do this after `ActiveStorage::Blob.create_and_upload!`.

Trash, duplicate, and manual ordering stay off. A trashed brand still fills a one mount, so restoring it cannot leave two brands there.

This gem does not implement Company, Person, Location, Press Centre, or Press Kit. Brand is not tied to a root or a Workspace.
