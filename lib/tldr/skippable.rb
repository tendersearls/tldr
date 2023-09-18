class TLDR
  class SkipTest < StandardError; end

  module Skippable
    def skip message = ""
      raise SkipTest, message
    end
  end
end
