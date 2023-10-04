class TLDR
  class BacktraceFilter
    BASE_PATH = __dir__.freeze

    def filter backtrace
      return ["No backtrace"] unless backtrace
      return backtrace.dup if $DEBUG

      trim_leading_frames(backtrace) ||
        trim_internal_frames(backtrace) ||
        backtrace.dup
    end

    private

    def trim_leading_frames backtrace
      if (trimmed = backtrace.take_while { |frame| meaningful?(frame) }).any?
        trimmed
      end
    end

    def trim_internal_frames backtrace
      if (trimmed = backtrace.select { |frame| meaningful?(frame) }).any?
        trimmed
      end
    end

    def meaningful? frame
      !internal?(frame)
    end

    def internal? frame
      frame.start_with?(BASE_PATH)
    end
  end

  def self.filter_backtrace backtrace
    BacktraceFilter.new.filter(backtrace)
  end
end
