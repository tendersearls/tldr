# While all the methods in this file were written for TLDR, they were designed
# to maximize compatibility with minitest's assertions here:
#
#   https://github.com/minitest/minitest/blob/master/lib/minitest/assertions.rb
#
# As a result, many implementations are extremely similar to those found in
# minitest. Any such implementatins are Copyright © Ryan Davis, seattle.rb and
# distributed under the MIT License

require "pp"
require "super_diff"

class TLDR
  module Assertions
    class Failure < Exception; end # standard:disable Lint/InheritException

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

    def assert_match? expected, actual, message = nil
      message = Assertions.msg(message) {
        "Expected #{Assertions.h(actual)} to match #{Assertions.h(expected)}"
      }
      assert_respond_to actual, :match?
      assert actual.match?(expected), message
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

    def assert_output std_out, std_err, message = nil
      message = Assertions.msg(message) {
        "Expected #{Assertions.h(left_operand)} to be #{operator} #{Assertions.h(right_operand)}"
      }
      assert left_operand.__send__(operator, right_operand), message
    end

    def assert_respond_to obj, method, message = nil
      message = Assertions.msg(message) {
        "Expected #{Assertions.h(obj)} (#{obj.class}) to respond to #{Assertions.h(method)}"
      }

      assert obj.respond_to?(method), message
    end
  end
end
