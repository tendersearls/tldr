# While all the methods in this file were written for TLDR, they were designed
# to maximize compatibility with minitest's assertions API and messages here:
#
#   https://github.com/minitest/minitest/blob/master/lib/minitest/assertions.rb
#
# As a result, many implementations are extremely similar to those found in
# minitest. Any such implementations are Copyright © Ryan Davis, seattle.rb and
# distributed under the MIT License

require "pp"
require "super_diff"
require_relative "assertions/minitest_compatibility"

class TLDR
  module Assertions
    def self.h obj
      obj.pretty_inspect.chomp
    end

    def self.msg message = nil, &default
      proc {
        message = message.call if Proc === message
        [message.to_s, default.call].reject(&:empty?).join("\n")
      }
    end

    def self.diff expected, actual
      SuperDiff::EqualityMatchers::Main.call(expected:, actual:)
    end

    def self.capture_io
      captured_stdout, captured_stderr = StringIO.new, StringIO.new

      original_stdout, original_stderr = $stdout, $stderr
      $stdout, $stderr = captured_stdout, captured_stderr

      yield

      [captured_stdout.string, captured_stderr.string]
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end

    def assert bool, message = nil
      message ||= "Expected #{Assertions.h(bool)} to be truthy"

      if bool
        true
      else
        message = message.call if Proc === message
        fail Failure, message
      end
    end

    def assert_equal expected, actual, message = nil
      message = Assertions.msg(message) { Assertions.diff expected, actual }
      assert expected == actual, message
    end

    def assert_empty obj, message = nil
      message = Assertions.msg(message) {
        "Expected #{Assertions.h(obj)} to be empty"
      }

      assert_respond_to obj, :empty?
      assert obj.empty?, message
    end

    def assert_in_delta expected, actual, delta, message = nil
      difference = (expected - actual).abs
      message = Assertions.msg(message) {
        "Expected |#{expected} - #{actual}| (#{difference}) to be within #{delta}"
      }
      assert delta >= difference, message
    end

    def assert_in_epsilon expected, actual, epsilon = 0.001, message = nil
      assert_in_delta expected, actual, [expected.abs, actual.abs].min * epsilon, message
    end

    def assert_include? expected, actual, message = nil
      message = Assertions.msg(message) {
        "Expected #{Assertions.h(actual)} to include #{Assertions.h(expected)}"
      }
      assert_respond_to actual, :include?
      assert actual.include?(expected), message
    end

    def assert_instance_of expected, actual, message = nil
      message = Assertions.msg(message) {
        "Expected #{Assertions.h(actual)} to be an instance of #{expected}, not #{actual.class}"
      }
      assert actual.instance_of?(expected), message
    end

    def assert_kind_of expected, actual, message = nil
      message = Assertions.msg(message) {
        "Expected #{Assertions.h(actual)} to be a kind of #{expected}, not #{actual.class}"
      }
      assert actual.is_a?(expected), message
    end

    def assert_match matcher, actual, message = nil
      message = Assertions.msg(message) {
        "Expected #{Assertions.h(actual)} to match #{Assertions.h(matcher)}"
      }
      assert_respond_to matcher, :=~
      assert matcher =~ actual, message
    end

    def assert_nil obj, message = nil
      message = Assertions.msg(message) {
        "Expected #{Assertions.h(obj)} to be nil"
      }

      assert obj.nil?, message
    end

    def assert_operator left_operand, operator, right_operand, message = nil
      message = Assertions.msg(message) {
        "Expected #{Assertions.h(left_operand)} to be #{operator} #{Assertions.h(right_operand)}"
      }
      assert left_operand.__send__(operator, right_operand), message
    end

    def assert_output expected_stdout, expected_stderr, message = nil, &block
      assert_block "assert_output requires a block to capture output." unless block

      actual_stdout, actual_stderr = Assertions.capture_io(&block)

      if Regexp === expected_stderr
        assert_match expected_stderr, actual_stderr, "In stderr"
      elsif !expected_stderr.nil?
        assert_equal expected_stderr, actual_stderr, "In stderr"
      end

      if Regexp === expected_stdout
        assert_match expected_stdout, actual_stdout, "In stdout"
      elsif !expected_stdout.nil?
        assert_equal expected_stdout, actual_stdout, "In stdout"
      end
    end

    def assert_path_exists path, message = nil
      message = Assertions.msg(message) {
        "Expected #{Assertions.h(path)} to exist"
      }

      assert File.exist?(path), message
    end

    def assert_pattern message = nil
      assert false, "assert_pattern requires a block to capture errors." unless block_given?

      begin
        yield
      rescue NoMatchingPatternError => e
        assert false, Assertions.msg(message) { "Expected pattern match: #{e.message}" }
      end
    end

    def assert_predicate obj, method, message = nil
      message = Assertions.msg(message) {
        "Expected #{Assertions.h(obj)} to be #{method}"
      }

      assert obj.send(method), message
    end

    def assert_raises *exp
      assert false, "assert_raises requires a block to capture errors." unless block_given?

      message = exp.pop if String === exp.last
      exp << StandardError if exp.empty?

      begin
        yield
      rescue Failure, Skip
        raise
      rescue *exp => e
        return e
      rescue SignalException, SystemExit
        raise
      rescue Exception => e # standard:disable Lint/RescueException
        assert false, Assertions.msg(message) {
          [
            "#{Assertions.h(exp)} exception expected, not",
            "Class: <#{e.class}>",
            "Message: <#{e.message.inspect}>",
            "---Backtrace---",
            TLDR.filter_backtrace(e.backtrace).join("\n"),
            "---------------"
          ].compact.join "\n"
        }
      end

      exp = exp.first if exp.size == 1

      assert false, "#{message}#{Assertions.h(exp)} expected but nothing was raised."
    end

    def assert_respond_to obj, method, message = nil
      message = Assertions.msg(message) {
        "Expected #{Assertions.h(obj)} (#{obj.class}) to respond to #{Assertions.h(method)}"
      }

      assert obj.respond_to?(method), message
    end

    def assert_same expected, actual, message = nil
      message = Assertions.msg(message) {
        <<~MSG
          Expected objects to be the same, but weren't
          Expected: #{Assertions.h(expected)} (oid=#{expected.object_id})
          Actual: #{Assertions.h(actual)} (oid=#{actual.object_id})
        MSG
      }
      assert expected.equal?(actual), message
    end

    def assert_silent
      assert_output "", "" do
        yield
      end
    end

    def assert_throws expected, message = nil
      punchline = nil
      caught = true
      value = catch(expected) do
        begin
          yield
        rescue ArgumentError => e
          raise e unless e.message.include?("uncaught throw")
          punchline = ", not #{e.message.split(" ").last}"
        end
        caught = false
      end

      assert caught, Assertions.msg(message) {
        "Expected #{Assertions.h(expected)} to have been thrown#{punchline}"
      }
      value
    end
  end
end
