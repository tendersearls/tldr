class TLDR
  module Assertions
    class Failure < Exception; end # standard:disable Lint/InheritException

    def assert bool, message = nil
      message ||= <<~MESSAGE
        Expected #{bool.inspect} to be truthy.
      MESSAGE

      fail Failure, message unless bool
    end

    def assert_equal expected, actual, message = nil
      message ||= <<~MESSAGE
        Expected: #{expected.inspect}
        Actual: #{actual.inspect}
      MESSAGE
      fail Failure, message unless expected == actual
    end
  end
end
