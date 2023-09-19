# These methods are provided only for drop-in compatibility with Minitest:
#
#   require "tldr/assertions/minitest"
#
# Will load these methods for use in your tests
class TLDR
  module Assertions
    def assert_includes actual, expected, message = nil
    end
  end
end
