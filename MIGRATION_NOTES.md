# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 4.x (`~> 4.2` in the gemspec; dummy GitHub tag `v4.6.0`)
- Accessible dummy tag `v0.18.0` and Root Switchable dummy tag `v0.9.0`
- Admin gemspec `~> 2.0` (dummy GitHub tag `v2.3.2`)
- Trashable dummy tag `v0.10.0` (`require: false`; query-only for Accessible 0.17+)
- Cache dummy tag `v0.5.0` (required by Root Switchable 0.9+)
- Metrics dummy tag `v0.2.3` (required by Admin 2.3+, Attachable 0.14+, Root Switchable 0.7+, Trashable)
- Attachable dummy tag `v0.15.0` (unchanged; do not bump Attachable from this gem)
- FlatPack dummy tag `v0.1.213`
- Public RubyGems and GitHub access for dependency installation

## Installing catalogue fields (0.4.0+)

Hosts upgrading onto Brands catalogue fields should copy the engine migrations and migrate:

```bash
bin/rails generate recording_studio_brands:migrations
bin/rails db:migrate
```

The catalogue migration adds `slug`, `active`, and `metadata` on `recording_studio_brands`. Empty slugs are backfilled in Ruby with `String#parameterize` (so names like `Café` become `cafe`). When more than one brand under the same parent would share a base slug, later rows get `-2`, `-3`, … suffixes.

## Verification

Install both bundles and run the complete gem and dummy app test path:

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

Run the dummy app from its directory for browser verification:

```bash
cd test/dummy
bin/dev
```

Use the [FlatPack repository](https://github.com/bowerbird-app/flatpack) and the live FlatPack demo linked from the top-level README for current component documentation.
