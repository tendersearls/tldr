require "optparse"

class TLDR
  class ArgvParser
    PATTERN_FRIENDLY_SPLITTER = /,(?=(?:[^\/]*\/[^\/]*\/)*[^\/]*$)/

    def parse args, options = {cli_defaults: true}
      OptionParser.new do |opts|
        opts.banner = "Usage: tldr [options] some_tests/**/*.rb some/path.rb:13 ..."

        opts.on CONFLAGS[:fail_fast], "Stop running tests as soon as one fails" do |fail_fast|
          options[:fail_fast] = fail_fast
        end

        opts.on "-s", "#{CONFLAGS[:seed]} SEED", Integer, "Seed for randomization" do |seed|
          options[:seed] = seed
        end

        opts.on CONFLAGS[:parallel], "Parallelize tests (Default: true)" do |parallel|
          options[:parallel] = parallel
        end

        opts.on "-n", "#{CONFLAGS[:names]} PATTERN", "One or more names or /patterns/ of tests to run (like: foo_test, /test_foo.*/, Foo#foo_test)" do |name|
          options[:names] ||= []
          options[:names] += name.split(PATTERN_FRIENDLY_SPLITTER)
        end

        opts.on "#{CONFLAGS[:exclude_names]} PATTERN", "One or more names or /patterns/ NOT to run" do |exclude_name|
          options[:exclude_names] ||= []
          options[:exclude_names] += exclude_name.split(PATTERN_FRIENDLY_SPLITTER)
        end

        opts.on "#{CONFLAGS[:exclude_paths]} PATH", Array, "One or more paths NOT to run (like: foo.rb, \"test/bar/**\", baz.rb:3)" do |path|
          options[:exclude_paths] ||= []
          options[:exclude_paths] += path
        end

        opts.on "#{CONFLAGS[:helper_paths]} PATH", Array, "One or more paths to a helper that is required before any tests (Default: \"test/helper.rb\")" do |path|
          options[:helper_paths] ||= []
          options[:helper_paths] += path
        end

        opts.on CONFLAGS[:no_helper], "Don't require any test helpers" do
          options[:no_helper] = true
        end

        opts.on "#{CONFLAGS[:prepend_paths]} PATH", Array, "Prepend one or more paths to run before the rest (Default: most recently modified test)" do |prepend|
          options[:prepend_paths] ||= []
          options[:prepend_paths] += prepend
        end

        opts.on CONFLAGS[:no_prepend], "Don't prepend any tests before the rest of the suite" do
          options[:no_prepend] = true
        end

        opts.on "-l", "#{CONFLAGS[:load_paths]} PATH", Array, "Add one or more paths to the $LOAD_PATH (Default: [\"test\"])" do |load_path|
          options[:load_paths] ||= []
          options[:load_paths] += load_path
        end

        opts.on "-r", "#{CONFLAGS[:reporter]} REPORTER", String, "Set a custom reporter class (Default: \"TLDR::Reporters::Default\")" do |reporter|
          options[:reporter] = Kernel.const_get(reporter)
        end

        opts.on "#{CONFLAGS[:base_path]} PATH", String, "Change the working directory for all relative paths (Default: current working directory)" do |path|
          options[:base_path] = path
        end

        opts.on CONFLAGS[:no_dotfile], "Disable loading .tldr.yml dotfile" do
          options[:no_dotfile] = true
        end

        opts.on CONFLAGS[:no_emoji], "Disable emoji in the output" do
          options[:no_emoji] = true
        end

        opts.on "-v", CONFLAGS[:verbose], "Print stack traces for errors" do |verbose|
          options[:verbose] = verbose
        end

        opts.on CONFLAGS[:warnings], "Print Ruby warnings (Default: true)" do |warnings|
          options[:warnings] = warnings
        end

        opts.on CONFLAGS[:yes_i_know], "Suppress TLDR report when suite runs over 1.8s" do
          options[:yes_i_know] = true
        end

        opts.on CONFLAGS[:potential_flake], "Print advice when a potentially flaky test is run in isolation" do
          options[:potential_flake] = true
        end

        opts.on "--comment COMMENT", String, "No-op; used for multi-line execution instructions" do
          # See "--comment" in lib/tldr/reporters/default.rb for an example of how this is used internally
        end
      end.parse!(args)

      options[:paths] = args if args.any?

      Config.new(**options)
    end
  end
end
