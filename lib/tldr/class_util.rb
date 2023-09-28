class TLDR
  module ClassUtil
    def self.gather_descendants root_klass
      root_klass.subclasses + root_klass.subclasses.flat_map { |subklass|
        gather_descendants subklass
      }
    end

    def self.gather_tests klass
      klass.instance_methods.grep(/^test_/).sort.map { |method|
        Test.new klass, method
      }
    end
  end
end
