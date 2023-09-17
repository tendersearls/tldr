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
      end.parse!(args)

      config.paths = args if args.any?

      config
    end
  end
end
