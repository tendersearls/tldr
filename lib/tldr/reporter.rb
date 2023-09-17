class TLDR
  class Reporter
    def report results
      exit_code = if results.any? { |result| !result.error.nil? && !result.error.is_a?(Assertions::Failure) }
        2
      elsif results.any? { |result| result.error.is_a?(Assertions::Failure) }
        1
      else
        0
      end

      exit exit_code
    end
  end
end
