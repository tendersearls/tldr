class TLDR
  class SkipTest < StandardError; end

  module Skippable
    def skip message = nil
      raise SkipTest, message
    end
  end
end
