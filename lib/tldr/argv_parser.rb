require "optparse"

class TLDR
  class ArgvParser
    def parse(args)
      config = Config.new

      OptionParser.new do |opts|
        opts.banner = "Usage: tldr [options] path1 path2 ..."

        opts.on("-s", "--seed SEED", Integer, "Seed for randomization") do |seed|
          config.seed = seed
        end

        opts.on("-r", "--reporter REPORTER", String, "Custom reporter class (Default: \"TLDR::Reporters::Default\")") do |reporter|
          config.reporter = Kernel.const_get(reporter).new
        end

        opts.on("--skip-test-helper", "Don't load test/test_helper.rb") do |skip_test_helper|
          config.skip_test_helper = skip_test_helper
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
