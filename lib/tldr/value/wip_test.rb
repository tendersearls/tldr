class TLDR
  WIPTest = Struct.new(:test, :start_time, :thread) do
    attr_reader :backtrace_at_exit

    def capture_backtrace_at_exit
      @backtrace_at_exit = thread&.backtrace
    end
  end
end
