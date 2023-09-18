class TLDR
  class Reporter
    def report config, results
      errors = results.map { |result| result.error }.compact

      print_summary summarize config, results

      exit exit_code errors
    end

    private

    def print_summary summary
      $stdout.print "\n\n"
      summary.each.with_index do |summary, index|
        $stderr.print "#{index + 1}) #{summary}\n\n"
      end
    end

    def summarize config, results
      results.reject { |result| result.error.nil? }
        .sort_by { |result| result.test.location.relative }
        .map { |result|
          summarize_result config, result
        }
    end

    def summarize_result config, result
      [
        "#{result.type.to_s.capitalize}:",
        "#{result.test.klass}##{result.test.method} [#{result.relevant_location.relative}]:",
        result.error.message.chomp,
        <<~RERUN.chomp,

          Re-run this test:
            bundle exec tldr #{result.test.location.relative} #{config.to_single_args}
        RERUN
        (result.error.backtrace.join("\n") if config.verbose)
      ].compact.reject(&:empty?).join("\n").strip
    end

    def exit_code errors
      if errors.any? { |error| error? error }
        2
      elsif errors.any? { |error| failure? error }
        1
      else
        0
      end
    end

    def failure? error
      error.is_a?(Assertions::Failure)
    end

    def skip? error
      error.is_a?(SkipTest)
    end

    def error? error
      !error.nil? && !error.is_a?(Assertions::Failure) && !error.is_a?(SkipTest)
    end
  end
end
