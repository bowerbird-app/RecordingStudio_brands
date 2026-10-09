# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-10-09

### Added

* English Rails I18n keys for static interface copy in the gem's own brand
  screens (`config/locales/en.yml` under `recording_studio.brands`)

### Changed

* Brand view and helper labels (titles, buttons, form labels, empty states,
  conflict alert, logo button, contact row labels) resolve through `t(...)`
  (English output unchanged)

### Upgrade notes

- No migration or host code change is required for English.
- To translate or override the defaults, add keys under
  `recording_studio.brands` in the host's locale files.
- There is no dependency on `recording_studio_internationalization`.
- ActiveRecord attribute labels under
  `activerecord.attributes.recording_studio_brands/brand` are unchanged.

## [0.1.0] - 2026-10-06

### Added

- `RecordingStudioBrands::Brand`, a public identity with name, tagline, description, website, email, phone, and one logo.
- `RecordingStudio::Capabilities::Brand.to(allows: :one)` and `allows: :many`. The parent class chooses the limit. A one mount refuses a second brand when the recording is created.
- Screens to view, add, and edit a brand. The brand page shows the details in one card. A many mount lists brand names in a card in the first column of a two-column grid. The edit screen has one button to replace the logo.
- Install and migration generators, plus a dummy host where a workspace and a folder each hold many brands. A host can still opt a parent into one brand.

### Upgrade

0.1.0 is the first release. There is no earlier brand schema to migrate.

1. Add `recording_studio_brands` and `recording_studio_attachable`.
2. Run `bin/rails generate recording_studio_attachable:install`, `bin/rails generate recording_studio_attachable:migrations`, `bin/rails generate recording_studio_brands:install`, and `bin/rails generate recording_studio_brands:migrations`.
3. Run `bin/rails db:migrate`.
4. Add `"RecordingStudioBrands::Brand"` and `"RecordingStudioAttachable::Attachment"` to `config.recordable_types`.
5. Include `RecordingStudio::Capabilities::Brand.to(allows: :one)` or `allows: :many` on each parent class that should hold brands. Brand does not pick a default, and it does not name Company, Person, Workspace, or any other parent.
6. Rebuild Tailwind CSS so the brand screens are styled.

Company, Person, Location, Press Centre, and Press Kit are not part of this gem. Trash, duplicate, and manual ordering stay off.

[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_brands/releases/tag/v0.2.0
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_brands/releases/tag/v0.1.0
