require_relative "tldr/version"

class TLDR
  class Error < StandardError; end

  module Assertions
    class Failure < Exception; end # standard:disable Lint/InheritException

    def assert bool, message = nil
      fail Failure, message unless bool
    end
  end

  include Assertions

  Plan = Struct.new :tests
  Test = Struct.new :klass, :method
  TestResult = Struct.new :test, :error

  def self.plan
    tests = TLDR.subclasses.flat_map { |subklass|
      subklass.instance_methods.grep(/^test_/).map { |method|
        Test.new subklass, method
      }
    }
    Plan.new tests
  end

  def self.run plan
    Thread.new {
      sleep 1.8
      puts "Too Long Didn't Run"
      exit!
    }

    plan.tests.shuffle.map { |test|
      begin
        instance = test.klass.new
        instance.send(test.method)
        $stdout.print "💯"
      rescue Failure => e
        $stderr.print "🙏"
      rescue => e
        $stderr.print "😬"
      end
      TestResult.new test, e
    }
  end

  def self.report results
    exit_code = if results.any? { |result| !result.error.nil? && !result.error.is_a?(Failure) }
      2
    elsif results.any? { |result| result.error.is_a?(Failure) }
      1
    else
      0
    end

    exit exit_code
  end
end
