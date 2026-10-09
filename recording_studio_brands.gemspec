# frozen_string_literal: true

require_relative "lib/recording_studio_brands/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_brands"
  spec.version     = RecordingStudioBrands::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_brands"
  spec.summary     = "Brand recordings for Recording Studio hosts"
  spec.description = "A Rails engine that records a Brand, a public identity, under the recordables a host " \
                     "chooses. Each parent type allows one brand or many."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bowerbird-app/RecordingStudio_brands"
  spec.metadata["changelog_uri"] = "https://github.com/bowerbird-app/RecordingStudio_brands/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"].reject do |path|
      path == ".cursor" || path.start_with?(".cursor/")
    end
  end

  spec.add_dependency "flat_pack", ">= 0.1.196"
  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio", "~> 4.2"
  spec.add_dependency "recording_studio_accessible", "~> 0.13"
  spec.add_dependency "recording_studio_attachable", "~> 0.13"
end
