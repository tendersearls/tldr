class TLDR
  module Assertions
    class Failure < Exception; end

    def assert bool, message = nil
      fail Failure, message unless bool
    end
  end

  include Assertions

  class Plan
    def initialize tests
      @tests = tests
    end

    def run!
      Thread.new {
        sleep 1.8
        puts "Too Long Didn't Run"
        exit!
      }
      @tests.shuffle.each(&:run!)
      puts
    end
  end

  Test = Struct.new :klass, :method do
    def run!
      instance = klass.new
      instance.send(method)
      print "💯"
    rescue Failure
      print "🙏"
    rescue
      print "😬"
    end
  end

  def self.plan file_list
    tests = TLDR.subclasses.flat_map { |subklass|
      subklass.instance_methods.grep(/^test_/).map { |method|
        Test.new subklass, method
      }
    }
    Plan.new tests
  end
end

class FunTest < TLDR
  def test_passes
    assert true
  end

  def test_false
    assert false
  end

  def test_hello
    raise "💥"
  end
end

plan = TLDR.plan [__FILE__]
plan.run!
