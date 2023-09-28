class TLDR
  TestGroup = Struct.new :configuration do
    attr_writer :tests

    def tests
      @tests ||= configuration.flat_map { |(klass, method)|
        klass = Kernel.const_get(klass) if klass.is_a? String
        if method.nil?
          ([klass] + ClassUtil.gather_descendants(klass)).flat_map { |klass|
            ClassUtil.gather_tests(klass)
          }
        else
          Test.new klass, method
        end
      }
    end

    def group?
      true
    end
  end
end
