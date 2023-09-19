require "optparse"

class TLDR
  class ArgvParser
    def parse(args)
      config = Config.new

      OptionParser.new do |opts|
        opts.banner = "Usage: tldr [options] some_tests/**/*.rb some/path.rb:13 ..."

        opts.on("-s", "--seed SEED", Integer, "Seed for randomization") do |seed|
          config.seed = seed
        end

        opts.on("-r", "--reporter REPORTER", String, "Custom reporter class (Default: \"TLDR::Reporters::Default\")") do |reporter|
          config.reporter = Kernel.const_get(reporter).new
        end

        opts.on("-l", "--load-path PATH", String, "Add one or more paths to the $LOAD_PATH (Default: [\"test\"])") do |load_path|
          config.load_paths << load_path
        end

        opts.on("--helper HELPER", String, "Path to a test helper to load before any tests (Default: \"test/helper.rb\")") do |helper|
          config.helper = helper
        end

        opts.on("--skip-test-helper", "Don't try loading a test helper before the tests") do |skip_test_helper|
          config.skip_test_helper = skip_test_helper
        end

        opts.on("--workers WORKERS", Integer, "Number of parallel workers (Default: #{Concurrent.processor_count}, the number of CPU cores)") do |workers|
          config.workers = workers
        end

        opts.on("-v", "--verbose", "Print stack traces for errors") do |verbose|
          config.verbose = verbose
        end
      end.parse!(args)

      config.paths = args if args.any?

      config
    end
  end
end
