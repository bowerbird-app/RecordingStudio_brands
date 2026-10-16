# RecordingStudioBrands

Brand is a public identity a host can record under any recording it allows. A workspace can hold one brand. A folder, project, or event can hold many. The same app can do both. The limit belongs to the parent, and it is enforced when the brand is saved.

The type string is `RecordingStudioBrands::Brand`.

Brand does not require a root, a Workspace, a Company, or a Person. This gem does not implement Company, Person, Location, Press Centre, or Press Kit.

## A brand

| Field | Rule |
| --- | --- |
| Name | Required. 255 characters. |
| Slug | Required. 255 characters. Unique among current brands under the same parent. Filled from the parameterized name when blank. |
| Tagline | Optional. 255 characters. |
| Description | Optional. 5,000 characters. |
| Website | Optional. 255 characters. Normalized on assign (`RecordingStudioBrands::Url.normalize`). |
| Email | Optional. 255 characters. Stored as entered. |
| Phone | Optional. 255 characters. Stored as entered. |
| Active | Boolean, default true. Catalogue “live” flag. |
| Metadata | JSON object, default `{}`. Opaque bag for hosts. |
| Logo | One image on the brand recording. A new image replaces it. |

Optional text fields are length-capped only. There is no format check for email or phone.

The logo uses Recording Studio Attachable. Revise copies the brand row and drops file attachments on that row, so the logo hangs off the brand recording and stays put.

Trash, duplicate, and manual ordering are off. A trashed brand still fills a one mount, because the limit counts every brand row. Restoring it cannot leave two brands there.

## How a host mounts it

Register the type, then opt in on each parent class. There is no default.

```ruby
RecordingStudio.configure do |config|
  config.recordable_types += [
    "RecordingStudioBrands::Brand",
    "RecordingStudioAttachable::Attachment",
    "RecordingStudioAttachable::Library",
    "RecordingStudioAttachable::Placement"
  ]
end

class Project < ApplicationRecord
  recording_studio_recordable label: "Project", root: false
  include RecordingStudio::Capabilities::Brand.to(allows: :many)
end
```

`allows: :one` keeps a single brand. The empty screen offers Add. Once a brand exists, the screen shows it and refuses a second. `allows: :many` shows the list and keeps Add. A parent that never includes `Brand.to` has no brand screens.

`Brand.to` is required. Passing anything other than `:one` or `:many` fails when the parent class loads.

Save and revise through Recording Studio. Pass `parent_recording` so a non-root parent is not replaced by the root.

```ruby
brand_recording = project_recording.record(
  RecordingStudioBrands::Brand,
  parent_recording: project_recording,
  actor: current_user
) { |brand| brand.name = "Acme Coffee" }

project_recording.revise(brand_recording, actor: current_user) { |brand| brand.tagline = "Roasted for the launch" }
```

A second `record` under an `allows: :one` parent raises `RecordingStudioBrands::BrandLimitReached` and creates no recording. The error is a `RecordingStudio::InvalidParent`, so code that rescues placement errors catches it. `revise` never raises it. If you rescue the error inside your own transaction, roll that transaction back. Otherwise the Brand row that `record` saved stays without a recording.

Read a parent's brands with `RecordingStudioBrands::Mount.for`. It returns `nil` when the parent class does not include `Brand.to`.

```ruby
case RecordingStudioBrands::Mount.for(parent_recording)
in RecordingStudioBrands::Mount::One => mount then mount.brand_recording
in RecordingStudioBrands::Mount::Many => mount then mount.brand_recordings
in nil then nil
end
```

`brand_recordings` lists every brand recording under the parent, oldest first, trashed ones included. `brand_recording` returns the brand recording or `nil`. It raises `RecordingStudioBrands::MountConflict` when a one mount holds several brands, for example after the parent class changed from `allows: :many`.

Other gems can read `brand_recording.recordable` and follow the recording parent. They should not assume the parent is a Company, a Person, or a Workspace.

Find a current brand (the recordable a Brand recording points at now) with `RecordingStudioBrands::Identity`:

```ruby
RecordingStudioBrands::Identity.find_brand(slug: "acme-coffee", parent_recording: catalogue_recording)
RecordingStudioBrands::Identity.find_brand_recording(name: "Acme Coffee", parent_recording: catalogue_recording)
RecordingStudioBrands::Identity.find_brand(website_url: "acme.example", parent_recording: catalogue_recording)
```

When writing brands outside this gem's controllers, set
`brand.parent_recording_id_for_slug = parent.id` before validation so slug
uniqueness can scope to that parent. On revise, also set
`brand.slug_uniqueness_except_recording_id = brand_recording.id` so the
still-current snapshot does not collide with itself. Missing parent context
raises `ArgumentError` instead of skipping the uniqueness check.

Install catalogue columns with
`bin/rails generate recording_studio_brands:migrations` then
`bin/rails db:migrate`. Empty slugs are backfilled with `String#parameterize`
(so `Café` becomes `cafe`); duplicate base slugs under one parent get `-2`,
`-3`, … suffixes.

## Screens

The engine mounts at `/recording_studio_brands`.

- `GET /recordings/:recording_id/brands` is the brand home. One mount shows the brand or an empty state. Many mounts list each brand's name in a card, in the first column of a two-column grid.
- A one mount that already holds several brands lists them with a warning and hides Add.
- Add and edit save through `record` and `revise`.
- The brand page is titled Brand. The name and the other details sit in one card. The edit screen has one button that replaces the logo.

Screens call Accessible with the signed-in actor. A viewer can open a brand. Add, edit, and logo upload need edit access. Brand does not enable its own access capability. Access is inherited from the recording the host already authorized.

The engine defaults to `authenticate_user!` and `current_user`. Override both in `config/initializers/recording_studio_brands.rb` when the host uses different method names.

## Admin

This gem registers a Recording Studio Admin section (`brands`), screen
(`recording_studio_brands`), and resource for staff CRUD under the current root.
Forms live on the engine at `/recording_studio_brands/admin/brands`.

Hosts that need Media brands admin after publications drops its Brand screens:

1. Depend on `recording_studio_admin` and mount it (`recording_studio_admin_for`).
2. Enable `section :brands` on the admin root recordable (`AllowsAdminSections`).
3. Include `RecordingStudio::Capabilities::Brand.to(allows: :many)` on the root
   that should hold those brands (often the Catalogue root, or an AdminRoot in
   the dummy).
4. Grant Accessible access on the admin access recording.

The dummy mounts Admin at `/admin` with `AdminRoot` as a many-brand parent.

### Interface text

Static interface copy on the gem's brand screens and controller flashes uses
Rails I18n keys under `recording_studio.brands` in `config/locales/en.yml`.
The gem ships English only. A host's own `config/locales` files win when they
define the same keys (Rails loads host locales after the engine). Brand names
and other database content stay untranslated.

## Install

Add the gem and its siblings. They are fetched from GitHub in this repo. The gemspec pins the versions below.

```ruby
gem "recording_studio_brands"
```

From the host app:

```bash
bin/rails generate recording_studio_attachable:install
bin/rails generate recording_studio_attachable:migrations
bin/rails generate recording_studio_brands:install
bin/rails generate recording_studio_brands:migrations
bin/rails db:migrate
bin/rails tailwindcss:build
```

Then register the two type strings, opt each parent in with `allows: :one` or `allows: :many`, and confirm auth, layout, and current actor integration. The install generator prints the same steps.

### Upgrade from the template

0.1.0 is the first release. Hosts that copied the addon template and want Brand:

1. Add `recording_studio_brands` and `recording_studio_attachable`.
2. Run the install and migration generators above, then `bin/rails db:migrate`.
3. Add `"RecordingStudioBrands::Brand"`, `"RecordingStudioAttachable::Attachment"`, `"RecordingStudioAttachable::Library"`, and `"RecordingStudioAttachable::Placement"` to `config.recordable_types`.
4. Include `RecordingStudio::Capabilities::Brand.to(allows: :one)` or `allows: :many` on each parent class that should hold brands.
5. Rebuild Tailwind so the brand screens pick up Flatpack classes.

No data migration is required. There is no earlier brand table.

## Where brands sit

These trees are conceptual. This gem records only the Brand rows. The parents come from the host.

```text
Company
  Dove
  Rexona
  Ben & Jerry's

Person
  Taylor Swift

Project
  Acme Launch
```

A later host can place Press Centre under a Brand, then Press Kit and Messages under that. Those are separate gems.

## Dummy app

`test/dummy` is a host that is not Company or Person. Workspace and Folder both allow many brands. Page allows none. A host that wants a single brand still opts in with `allows: :one`.

Sign in as `admin@admin.com` / `Password`. Studio Workspace holds Taylor Swift, Dove, and Acme Coffee. Product Docs holds Nike, Dove, and Acme Coffee. Client Workspace is empty, so you can add the first brand. Private Workspace is not shared with that user.

```bash
cd test/dummy
bin/rails db:setup
bin/dev
```

Open port 3000. `/` lists the brand homes the signed-in user can see. `/users/sign_in` is Devise. `/recording_studio` redirects to `/`.

Cursor Cloud runs `.cursor/install.sh` and `.cursor/start.sh`. `environment.json` starts the Rails server, the Tailwind watcher, and port 3000.

Dummy credentials (`test/dummy/config/credentials.yml.enc`) use the shared Recording Studio development master key. Set `RAILS_MASTER_KEY` or `test/dummy/config/master.key`.

## Testing

From the repository root:

```bash
bundle exec rake test:all
```

That runs the engine tests and the dummy app. The dummy covers one and many mounts, the create guard, revise, validation, the type string, the logo, inherited access, and the home page.

## Dependencies

| Component | Pin |
| --- | --- |
| Ruby | 3.3+ |
| Rails | `~> 8.1.0` |
| Recording Studio | `~> 4.2` in the gemspec. dummy GitHub tag `v4.6.0`. |
| Accessible | `~> 0.13`. dummy GitHub tag `v0.18.0`. |
| Attachable | `~> 0.15`. dummy GitHub tag `v0.15.0`. |
| Trashable | Query-only for Accessible 0.17+. dummy GitHub tag `v0.10.0` (`require: false`). |
| Root Switchable | Dummy only. dummy GitHub tag `v0.9.0`. |
| Cache | Dummy only (Root Switchable 0.9+). dummy GitHub tag `v0.5.0`. |
| Metrics | Attachable 0.14+, Root Switchable 0.7+, Trashable. dummy GitHub tag `v0.2.0`. |
| Flatpack | `>= 0.1.196`. dummy GitHub tag `v0.1.213` (Attachable 0.12+ needs `>= 0.1.213`). |

`docs/gem_template/` is the frozen addon template this repo started from. This README is the source of truth for Brand.
