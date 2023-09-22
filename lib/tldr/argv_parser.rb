require "optparse"

class TLDR
  class ArgvParser
    def parse(args)
      config = Config.new

      OptionParser.new do |opts|
        opts.banner = "Usage: tldr [options] some_tests/**/*.rb some/path.rb:13 ..."

        opts.on(CONFLAGS[:fail_fast], "Stop running tests as soon as one fails") do |fail_fast|
          config.fail_fast = fail_fast
        end

        opts.on("-n", "#{CONFLAGS[:names]} PATTERN", Array, "One or more names or /pattern/ of tests to run (like: foo_test, /foo_.*/, Foo#foo_test)") do |name|
          config.names += name
        end

        opts.on("-s", "#{CONFLAGS[:seed]} SEED", Integer, "Seed for randomization") do |seed|
          config.seed = seed
        end

        opts.on("#{CONFLAGS[:workers]} WORKERS", Integer, "Number of parallel workers (Default: #{Concurrent.processor_count}, the number of CPU cores)") do |workers|
          config.workers = workers
        end

        opts.on("#{CONFLAGS[:helper]} HELPER", String, "Path to a test helper to load before any tests (Default: \"test/helper.rb\")") do |helper|
          config.helper = helper
        end

        opts.on(CONFLAGS[:skip_test_helper], "Don't try loading a test helper before the tests") do |skip_test_helper|
          config.skip_test_helper = skip_test_helper
        end

        opts.on("#{CONFLAGS[:prepend_tests]} PATH", String, "Prepend one or more paths to run first (Default: your most recently modified test)") do |prepend|
          config.prepend_tests << prepend
        end

        opts.on("-l", "#{CONFLAGS[:load_paths]} PATH", Array, "Add one or more paths to the $LOAD_PATH (Default: [\"test\"])") do |load_path|
          config.load_paths += load_path
        end

        opts.on("-r", "#{CONFLAGS[:reporter]} REPORTER", String, "Custom reporter class (Default: \"TLDR::Reporters::Default\")") do |reporter|
          config.reporter = Kernel.const_get(reporter)
        end

        opts.on(CONFLAGS[:no_emoji], "Disable emoji in the output") do |no_emoji|
          config.no_emoji = true # Apparently optparse will treat --no-.* options as false
        end

        opts.on("-v", CONFLAGS[:verbose], "Print stack traces for errors") do |verbose|
          config.verbose = verbose
        end

        opts.on("--comment COMMENT", String, "No-op comment, used internally for multi-line execution instructions") do
          # See "--comment" in lib/tldr/reporters/default.rb for an example of how this is used internally
        end
      end.parse!(args)

      config.paths = args if args.any?

      config
    end
  end
end
