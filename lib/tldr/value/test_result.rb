class TLDR
  TLDR_LIB_REGEX = /lib\/tldr/

  TestResult = Struct.new :test, :error do
    attr_reader :type, :error_location

    def initialize(*args)
      super
      @type = determine_type
      @error_location = determine_error_location
    end

    def emoji
      case type
      when :success then "😁"
      when :failure then "😡"
      when :skip then "🫥"
      when :error then "🤬"
      end
    end

    def io
      (success? || skip?) ? $stdout : $stderr
    end

    def success?
      type == :success
    end

    def failure?
      type == :failure
    end

    def skip?
      type == :skip
    end

    def error?
      type == :error
    end

    def relevant_location
      error_location || test.location
    end

    private

    def determine_type
      if error.nil?
        :success
      elsif error.is_a?(Assertions::Failure)
        :failure
      elsif error.is_a?(SkipTest)
        :skip
      else
        :error
      end
    end

    def determine_error_location
      return if error.nil?

      raised_at = error.backtrace.find { |bt| bt !~ TLDR_LIB_REGEX }
      if (raise_matches = raised_at.match(/^(.*):(\d+):in .*$/))
        Location.new(raise_matches[1], raise_matches[2].to_i)
      end
    end
  end
end
