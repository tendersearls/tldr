# These methods are provided to support drop-in compatibility with Minitest. You
# can use them by mixing them into your test or into the `TLDR` base class
# itself:
#
#   class YourTest < TLDR
#     include TLDR::MinitestCompatibility
#
#     def test_something
#       # …
#     end
#   end
#
# The implementation of these methods is extremely similar or identical to those
# found in minitest itself, which is Copyright © Ryan Davis, seattle.rb and
# distributed under the MIT License
class TLDR
  module MinitestCompatibility
    def capture_io &blk
      Assertions.capture_io(&blk)
    end

    def mu_pp obj
      s = obj.inspect.encode(Encoding.default_external)

      if String === obj && (obj.encoding != Encoding.default_external ||
                            !obj.valid_encoding?)
        enc = "# encoding: #{obj.encoding}"
        val = "#    valid: #{obj.valid_encoding?}"
        "#{enc}\n#{val}\n#{s}"
      else
        s
      end
    end

    def name
    end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def make_my_diffs_pretty!
        # No-op, because they're already pretty thanks to super_diff!
      end
    end
  end
end
