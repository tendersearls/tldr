class TLDR
  class Planner
    Test = Struct.new :klass, :method
    Plan = Struct.new :tests

    def plan config
      tests = TLDR.subclasses.flat_map { |subklass|
        subklass.instance_methods.grep(/^test_/).map { |method|
          Test.new subklass, method
        }
      }
      Plan.new tests
    end
  end
end
