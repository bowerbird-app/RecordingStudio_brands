# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.2] - 2026-10-28

### Changed

- Version `0.4.1` → `0.4.2`
- Stop tracking SimpleCov output under `coverage/` and `test/dummy/coverage/`; both directories are gitignored
- README Metrics dummy pin text matches the Gemfile tag `v0.2.3`
- Lockfile-only `crass` and `net-ssh` bumps
- CI: lint and security jobs use Ruby 3.3 (runner no longer has 3.3.6)
- FlatPack bumped to `v0.1.311` to fix Bundler Audit (`view_component` `>= 4.14`)
- Brands `one` view uses FlatPack `EmptyState#item`, which needs FlatPack `>= 0.1.246`; gemspec floor raised from `0.1.196`

### Upgrade notes

1. Bump to `recording_studio_brands` `0.4.2`. No schema or API change.
2. Regenerated coverage reports stay local; they are no longer in git.

## [0.4.1] - 2026-10-16

Tag `v0.4.1` points at `main` (`28f3f60`). `VERSION` on that commit stayed `0.4.0`; this section documents the tag.

### Changed

- Dummy and gem pins: `recording_studio_trashable` `v0.11.0` and Recording Studio `v4.7.0` (Trashable 0.11 requires `recording_studio ~> 4.7`)

### Upgrade notes

1. Hosts that pin from GitHub tags should use `v0.4.1` for this tree. Gem constant `RecordingStudioBrands::VERSION` on that tag is still `0.4.0`.
2. Dummy Trashable `v0.11.0` needs Recording Studio `v4.7.0`.

## [0.4.0] - 2026-10-16

### Added

- Catalogue fields on `RecordingStudioBrands::Brand`: `slug` (required), `active`
  (boolean, default true), and `metadata` (jsonb, default `{}`)
- Migration `add_catalogue_fields_to_recording_studio_brands` with indexes on
  `slug`, `website_url`, `active`, and `LOWER(name)`
- Ruby slug backfill via `String#parameterize`, with `-2` / `-3` … suffixes when
  the same parent would otherwise get duplicate slugs
- `RecordingStudioBrands::Url.normalize` for `website_url` — matches
  publications `Url.normalize` (`TRACKING_PARAM_PREFIXES` / `TRACKING_PARAMS`,
  parse, canonicalize, normalized_path, cleaned_query, tracking_param?).
  Delegates to `RecordingStudioPublications::Url.normalize` when loaded
- Catalogue migration embeds its own frozen copy of those normalize rules for
  legacy `website_url` backfill (does not call live `Url.normalize`)
- `RecordingStudioBrands::Identity.find_brand` / `find_brand_recording` for
  current brands by slug, name, or website under an optional parent
- Slug uniqueness among current brands under the same parent
- Recording Studio Admin section/screen/resource for Brands CRUD under the
  current root (`blast_radius :root`), with engine routes at
  `/recording_studio_brands/admin/brands`
- Gem dependency on `recording_studio_admin` `~> 2.0`

### Changed

- Version `0.3.0` → `0.4.0`
- Website values are normalized on assign to match publications Url rules
  (http→https, strip tracking params, empty path `/`, strip trailing slash on
  non-root paths, bare dotless names like `localhost` stay typed,
  `https://localhost` becomes `https://localhost/`). Host-only websites
  therefore display with a trailing `/` (for example `https://example.com/`)
- Slug is filled from the parameterized name when blank
- Dummy host mounts Admin with an `AdminRoot` that allows many brands
- Admin copy uses `RecordingStudio.t`; Brand metadata errors use ActiveModel keys
- Admin brand show uses FlatPack `List` instead of a raw definition list
- Brands `ApplicationController` matches sibling engines (`UsesDefaultLayout`,
  no host view-path prepend)
- Admin forms no longer permit `metadata` (column remains for programmatic use)
- Admin Brands index renders Active as a FlatPack Badge (success / default) and
  exposes a primary Add brand screen button
- Admin brand show list is full width with labels leading values
- Admin Brands screen/section/resource copy and table column titles defer i18n
  to request/render time; the catalogue table is built once in `register!`
- Missing slug parent context adds a validation error instead of raising

### Upgrade notes

1. Bump to `recording_studio_brands` `0.4.0` and add `recording_studio_admin`
   (`~> 2.0`; dummy pin `v2.3.2`).
2. Run `bin/rails generate recording_studio_brands:migrations` and
   `bin/rails db:migrate` so existing brand rows get `slug` / `active` /
   `metadata`. Slugs are backfilled with `parameterize`; duplicate base slugs
   under one parent become `name`, `name-2`, `name-3`, … Legacy `website_url`
   values are normalized so `Identity.find_brand(website_url:)` matches.
   Host-only sites gain a trailing `/` after normalize.
3. Mount Admin if hosts need Media brands CRUD when publications drops its
   Brand admin: enable a `brands` section on the admin root recordable, grant
   Accessible access, and ensure that root (or the switched root) includes
   `RecordingStudio::Capabilities::Brand.to(allows: :many)`.
4. Set `parent_recording_id_for_slug` on create/revise when writing brands
   outside this gem's controllers so slug uniqueness can scope to the parent.
   On revise, also set `slug_uniqueness_except_recording_id` to the Brand
   recording id. Missing parent context adds a slug validation error. The
   `SlugParentHook` fills these from `RecordingStudio.record!` when the parent
   recording is present.
5. Recordable UUIDs are unchanged by this release. Publications data copy and
   Channel parent cutover remain a later publications PR.
   `RecordingStudioBrands::Url.normalize` matches publications `Url.normalize`.

## [0.3.0] - 2026-10-13

### Added

- English Rails I18n keys for controller flash notices and alerts under
  `recording_studio.brands.flashes.*` (`brand_saved`, `logo_saved`,
  `logo_not_saved`, `brand_limit`)
- Locale regression: every `lib/**/*.rb` file must not mention
  `i18n.load_path` / `I18n.load_path`
- Always-loaded dummy host override on the rarely shown conflict title
  (`test/dummy/config/locales/recording_studio_brands.host.en.yml`) as the
  real boot-order guard, plus render-level asserts for flash English

### Changed

- Version `0.2.0` → `0.3.0`.
- Brand and logo controller notices/alerts resolve through
  `t(..., default: <main English>)` (English output unchanged). Parent type
  labels in flash interpolations stay raw from the parent recording.
- README documents that the host's `config/locales` wins for the same keys.

### Upgrade notes

- No migration or host code change is required for English.
- To translate or override flash copy, add keys under
  `recording_studio.brands.flashes` in the host's locale files.
- There is no dependency on `recording_studio_internationalization`.

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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_brands/compare/v0.4.2...HEAD
[0.4.2]: https://github.com/bowerbird-app/RecordingStudio_brands/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/bowerbird-app/RecordingStudio_brands/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/bowerbird-app/RecordingStudio_brands/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_brands/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_brands/releases/tag/v0.2.0
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_brands/releases/tag/v0.1.0
