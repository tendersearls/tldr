require_relative "lib/tldr/version"

Gem::Specification.new do |spec|
  spec.name = "tldr"
  spec.version = TLDR::VERSION
  spec.authors = ["Justin Searls", "Aaron Patterson"]
  spec.email = ["searls@gmail.com", "tenderlove@ruby-lang.org"]

  spec.summary = "TLDR will run your tests, but only for 1.8 seconds."
  spec.homepage = "https://github.com/tenderlove/tldr"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "super_diff", "~> 0.10"
  spec.add_dependency "concurrent-ruby", "~> 1.2"
end
