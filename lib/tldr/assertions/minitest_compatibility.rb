# These methods are provided only for drop-in compatibility with Minitest:
#
#   require "tldr/assertions/minitest"
#
# Will load these methods for use in your tests
#
# While all the methods in this file were written for TLDR, they were designed
# to maximize compatibility with minitest's assertions API and messages here:
#
#   https://github.com/minitest/minitest/blob/master/lib/minitest/assertions.rb
#
# As a result, many implementations are extremely similar to those found in
# minitest. Any such implementations are Copyright © Ryan Davis, seattle.rb and
# distributed under the MIT License

class TLDR
  module Assertions
    module MinitestCompatibility
      def assert_includes actual, expected, message = nil
        assert_include? expected, actual, message
      end

      def refute_includes actual, expected, message = nil
        refute_include? expected, actual, message
      end

      def assert_send receiver_method_args, message = nil
        warn "DEPRECATED: assert_send. From #{TLDR.filter_backtrace(caller).first}"
        receiver, method, *args = receiver_method_args
        message = Assertions.msg(message) {
          "Expected #{Assertions.h(receiver)}.#{method}(*#{Assertions.h(args)}) to return true"
        }

        assert receiver.__send__(method, *args), message
      end
    end
  end
end
