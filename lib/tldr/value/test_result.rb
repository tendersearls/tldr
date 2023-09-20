class TLDR
  TestResult = Struct.new :test, :error, :runtime do
    attr_reader :type, :error_location

    def initialize(*args)
      super
      @type = determine_type
      @error_location = determine_error_location
    end

    def emoji
      case type
      when :success then "😁"
      when :skip then "🫥"
      when :failure then "😡"
      when :error then "🤬"
      end
    end

    def passing?
      success? || skip?
    end

    def success?
      type == :success
    end

    def skip?
      type == :skip
    end

    def failure?
      type == :failure
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
      elsif error.is_a?(Failure)
        :failure
      elsif error.is_a?(Skip)
        :skip
      else
        :error
      end
    end

    def determine_error_location
      return if error.nil?

      raised_at = TLDR.filter_backtrace(error.backtrace).first
      if (raise_matches = raised_at.match(/^(.*):(\d+):in .*$/))
        Location.new(raise_matches[1], raise_matches[2].to_i)
      end
    end
  end
end
