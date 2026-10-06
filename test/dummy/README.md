# Dummy App

This Rails app exists to try Brand inside a host that is not Company or Person.

Workspace and Folder allow many brands. Page allows none. Studio Workspace is seeded with Taylor Swift, Dove, and Acme Coffee. Product Docs is seeded with Nike, Dove, and Acme Coffee. Client Workspace is empty. Private Workspace is not shared with the seeded admin.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- Owner access on Studio Workspace and Client Workspace
- Root workspace plus seeded folder, page, and brand recordables
- Recording Studio default layout, FlatPack assets, and Tailwind source scanning
- Mounted `RecordingStudio::Engine` and `RecordingStudioBrands::Engine` routes
- Dummy-only `/docs/*` pages for host setup

## Quick Start

```bash
cd test/dummy
bundle install
bin/rails db:setup
bin/dev
```

Run the commands above from the dummy app directory, not the repository root.

Then open the app and sign in with:

- Email: `admin@admin.com`
- Password: `Password`

## Useful Routes

- `/` - brand homes the signed-in user can open
- `/recording_studio` - redirects to `/` while the mounted Recording Studio engine stays available under that prefix for non-root routes
- `/users/sign_in` - Devise sign-in page
- `/docs/install`, `/docs/config`, `/docs/recordable_types`, `/docs/recordings_tree`, `/docs/gem_views`, `/docs/methods` - dummy-only setup pages
- `/up` - Rails health check

## Why This App Exists

Use this app to click through a list of brands before wiring Brand into another host. If a layout, route, asset source, or Recording Studio initializer change breaks here, fix it in this gem before a host copies the pattern.

Authenticated pages use Recording Studio's shared default layout. Devise sign-in keeps `layouts/application`.

The home page in `app/views/home/index.html.erb` stays a short list of brand homes. Setup detail lives on the dummy docs pages and in the repository README.
