class TLDR
  class Planner
    Test = Struct.new :klass, :method
    Plan = Struct.new :tests

    def plan config
      require_tests(config.paths)

      print_config config
      Plan.new gather_tests.tap { |tests|
        puts "debug CI"
        pp tests.map(&:method)
        pp Random.new(config.seed).rand
      }.shuffle(random: Random.new(config.seed))
    end

    private

    def require_tests(paths)
      paths.each do |path|
        path = File.absolute_path?(path) ? path : File.expand_path(path, Dir.pwd)
        require path
      end
    end

    def gather_tests
      TLDR.subclasses.flat_map { |subklass|
        subklass.instance_methods.grep(/^test_/).map { |method|
          Test.new subklass, method
        }
      }
    end

    def print_config config
      print "--seed #{config.seed}\n\n"
    end
  end
end
