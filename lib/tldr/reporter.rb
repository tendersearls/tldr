class TLDR
  class Reporter
    def report config, results
      config.reporter.after_suite config, results

      exit exit_code results
    end

    private

    def exit_code results
      if results.any? { |result| result.error? }
        2
      elsif results.any? { |result| result.failure? }
        1
      else
        0
      end
    end
  end
end
