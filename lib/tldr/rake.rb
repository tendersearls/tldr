desc "Run tests with TLDR (use TLDR_OPTS or .tldr.yml to configure)"
task :tldr do
  fail unless system "#{"bundle exec " if defined?(Bundler)}tldr #{ENV["TLDR_OPTS"]}"
end
