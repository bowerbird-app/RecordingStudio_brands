# RecordingStudioBrands

Brand is a public identity a host can record under any recording it allows. A workspace can hold one brand. A folder, project, or event can hold many. The same app can do both. The limit belongs to the parent, and it is enforced when the brand is saved.

The type string is `RecordingStudioBrands::Brand`.

Brand does not require a root, a Workspace, a Company, or a Person. This gem does not implement Company, Person, Location, Press Centre, or Press Kit.

## A brand

| Field | Rule |
| --- | --- |
| Name | Required. 255 characters. |
| Tagline | Optional. 255 characters. |
| Description | Optional. 5,000 characters. |
| Website | Optional. 255 characters. Stored as entered. |
| Email | Optional. 255 characters. Stored as entered. |
| Phone | Optional. 255 characters. Stored as entered. |
| Logo | One image on the brand recording. A new image replaces it. |

Optional fields are length-capped only. There is no format check for website, email, or phone.

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

## Screens

The engine mounts at `/recording_studio_brands`.

- `GET /recordings/:recording_id/brands` is the brand home. One mount shows the brand or an empty state. Many mounts list each brand's name in a card, in the first column of a two-column grid.
- A one mount that already holds several brands lists them with a warning and hides Add.
- Add and edit save through `record` and `revise`.
- The brand page is titled Brand. The name and the other details sit in one card. The edit screen has one button that replaces the logo.

Screens call Accessible with the signed-in actor. A viewer can open a brand. Add, edit, and logo upload need edit access. Brand does not enable its own access capability. Access is inherited from the recording the host already authorized.

The engine defaults to `authenticate_user!` and `current_user`. Override both in `config/initializers/recording_studio_brands.rb` when the host uses different method names.

### Interface text

Static interface copy on the gem's brand screens uses Rails I18n keys under
`recording_studio.brands` in `config/locales/en.yml`. The gem ships English
only. Hosts override or add languages in their own locale files. Brand names
and other database content stay untranslated. Flash notices built in
controllers are separate from these view keys.

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
| Recording Studio | `~> 4.2` in the gemspec. dummy GitHub tag `v4.4.0`. |
| Accessible | `~> 0.13`. dummy GitHub tag `v0.13.0`. |
| Attachable | `~> 0.13`. dummy GitHub tag `v0.13.0`. |
| Root Switchable | Dummy only. dummy GitHub tag `v0.6.0`. |
| Flatpack | `>= 0.1.196`. dummy GitHub tag `v0.1.213` (Attachable 0.12+ needs `>= 0.1.213`). |

`docs/gem_template/` is the frozen addon template this repo started from. This README is the source of truth for Brand.
