require "optparse"

class TLDR
  Config = Struct.new :paths, :seed, :skip_test_helper, keyword_init: true do
    def initialize(*args)
      super
      self.paths ||= Dir["test/**/*_test.rb"]
      self.seed ||= rand(10_000)
      self.skip_test_helper = false if skip_test_helper.nil?
    end
  end

  class ArgvParser
    def parse(args)
      config = Config.new

      OptionParser.new do |opts|
        opts.banner = "Usage: tldr [options] path1 path2 ..."

        opts.on("-s", "--seed SEED", Integer, "Seed for randomization") do |seed|
          config.seed = seed
        end

        opts.on("--skip-test-helper", "Don't load test/test_helper.rb") do |skip_test_helper|
          config.skip_test_helper = skip_test_helper
        end
      end.parse!(args)

      config.paths = args if args.any?

      config
    end
  end
end
