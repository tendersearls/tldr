class TLDR
  class Error < StandardError; end

  class Failure < Exception; end # standard:disable Lint/InheritException

  class Skip < StandardError; end

  INTERNAL_PATH_PATTERN = %r{/lib/tldr/}

  # This method was adapted from minitest's filter_backtrace method, found here:
  #
  #   https://github.com/minitest/minitest/blob/master/lib/minitest.rb#L1070
  #
  # Copyright © Ryan Davis, seattle.rb; distributed under the MIT License
  def self.filter_backtrace backtrace
    return ["No backtrace"] unless backtrace
    return backtrace.dup if $DEBUG

    filtered = backtrace.take_while { |line| line !~ INTERNAL_PATH_PATTERN }
    filtered = backtrace.select { |line| line !~ INTERNAL_PATH_PATTERN } if filtered.empty?
    filtered = backtrace.dup if filtered.empty?

    filtered
  end
end
