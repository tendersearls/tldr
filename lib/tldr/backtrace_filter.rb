class TLDR
  class BacktraceFilter
    BASE_PATH = __dir__.freeze
    SORBET_RUNTIME_PATTERN = %r{sorbet-runtime.*[/\\]lib[/\\]types[/\\]private[/\\]}
    CONCURRENT_RUBY_PATTERN = %r{concurrent-ruby.*[/\\]lib[/\\]concurrent-ruby[/\\]concurrent[/\\]}

    def filter backtrace
      return ["No backtrace"] unless backtrace
      return backtrace.dup if $DEBUG

      trim_leading_frames(backtrace) ||
        trim_internal_frames(backtrace) ||
        backtrace.dup
    end

    private

    def trim_leading_frames backtrace
      if (trimmed = backtrace.take_while { |frame| meaningful? frame }).any?
        trimmed
      end
    end

    def trim_internal_frames backtrace
      if (trimmed = backtrace.select { |frame| meaningful? frame }).any?
        trimmed
      end
    end

    def meaningful? frame
      !internal? frame
    end

    def internal? frame
      frame.start_with?(BASE_PATH) ||
        frame.match?(SORBET_RUNTIME_PATTERN) ||
        frame.match?(CONCURRENT_RUBY_PATTERN)
    end
  end

  def self.filter_backtrace backtrace
    BacktraceFilter.new.filter backtrace
  end
end
