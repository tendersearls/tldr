class TLDR
  module Skippable
    def skip message = ""
      raise Skip, message
    end
  end
end
