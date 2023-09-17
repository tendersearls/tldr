class TLDR
  module Assertions
    class Failure < Exception; end # standard:disable Lint/InheritException

    def assert bool, message = nil
      fail Failure, message unless bool
    end
  end
end
