# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_brands.gemspec
gemspec

# These gems are not published to RubyGems; resolve the gemspec pins from GitHub.
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.311"
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.7.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.18.0"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin", tag: "v2.3.2"
gem "recording_studio_attachable", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.15.0"
# Query-only trash helpers for Accessible 0.17+ (gemspec ~> 0.10). require: false —
# Accessible loads recording_studio_trashable/query only.
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable",
                                  tag: "v0.11.0", require: false
# Required by Attachable 0.14+ (site-wide attachment metrics); git source needs an explicit pin
gem "recording_studio_metrics", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.2.3",
                                require: false

gem "devise"
gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "minitest-mock"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
