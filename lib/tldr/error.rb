class TLDR
  class Error < StandardError; end

  class Failure < Exception; end # standard:disable Lint/InheritException

  class Skip < StandardError; end
end
