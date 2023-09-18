class TLDR
  module Reporters
    class Default < Base
      def initialize(out = $stdout, err = $stderr)
        out.sync = true
        err.sync = true

        @out = out
        @err = err
      end

      def before_suite tldr_config, tests
        @out.print "#{tldr_config.to_full_args}\n\n"
      end

      def after_tldr
        @err.print "🥵\n\ntoo long; didn't run"
      end

      def after_test result
        if result.passing?
          @out.print result.emoji
        else
          @err.print result.emoji
        end
      end

      def after_suite tldr_config, test_results
        summary = summarize tldr_config, test_results

        @out.print "\n\n"
        summary.each.with_index do |summary, index|
          @err.print "#{index + 1}) #{summary}\n\n"
        end
      end

      private

      def summarize config, results
        results.reject { |result| result.error.nil? }
          .sort_by { |result| result.test.location.relative }
          .map { |result| summarize_result config, result }
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
    end
  end
end
