require "pathname"

class TLDR
  class Planner
    def plan config
      require_test_helper(config)
      require_tests(config.paths)

      Plan.new(gather_tests.shuffle(random: Random.new(config.seed))).tap do |tests|
        config.reporter.before_suite config, tests
      end
    end

    private

    def require_test_helper(config)
      return if config.skip_test_helper || !File.exist?("test/test_helper.rb")
      require File.expand_path("test/test_helper.rb", Dir.pwd)
    end

    def require_tests(paths)
      paths.each do |path|
        path = File.absolute_path?(path) ? path : File.expand_path(path, Dir.pwd)
        require path
      end
    end

    def gather_tests
      TLDR.subclasses.flat_map { |subklass|
        subklass.instance_methods.grep(/^test_/).sort.map { |method|
          file, line = subklass.instance_method(method).source_location
          Test.new subklass, method, file, line
        }
      }
    end
  end
end
