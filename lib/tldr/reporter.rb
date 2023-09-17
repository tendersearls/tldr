class TLDR
  class Reporter
    def report results
      exit exit_code results
    end

    private

    def exit_code results
      errors = results.map { |result|
        next if result.error.is_a?(SkipTest)
        result.error
      }.compact

      if errors.any? { |error| !error.is_a?(Assertions::Failure) }
        2
      elsif errors.any?
        1
      else
        0
      end
    end
  end
end
