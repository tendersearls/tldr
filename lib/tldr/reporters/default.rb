class TLDR
  module Reporters
    class Default < Base
      def initialize(out = $stdout, err = $stderr)
        @tldr_tripped = Concurrent::AtomicBoolean.new false
        out.sync = true
        err.sync = true

        @out = out
        @err = err
      end

      def before_suite tldr_config, tests
        @out.print "#{tldr_config.to_full_args}\n\n"
      end

      def after_test result
        return if @tldr_tripped.true?

        if result.passing?
          @out.print result.emoji
        else
          @err.print result.emoji
        end
      end

      def time_diff(start, stop)
        ((stop - start) / 1000.0).round
      end

      def after_tldr tldr_config, planned_tests, wip_tests, test_results
        @tldr_tripped.make_true
        stop_time = Process.clock_gettime Process::CLOCK_MONOTONIC, :microsecond
        @err.print [
          "🥵",
          "too long; didn't run!",
          "🏃 Completed #{test_results.size} of #{planned_tests.size} tests (#{((test_results.size.to_f / planned_tests.size) * 100).round}%) before running out of time.",
          (<<~WIP.chomp if wip_tests.any?),
            🙅 These #{wip_tests.size} tests were cancelled in progress:
            #{wip_tests.map { |wip_test| "  #{time_diff(wip_test.start_time, stop_time)}ms - #{describe(wip_test.test)}" }.join("\n")}
          WIP
          (<<~SLOW.chomp if test_results.any?)
            🐢 Your #{[10, test_results.size].min} slowest completed tests:
            #{test_results.sort_by(&:runtime).last(10).reverse.map { |result| "  #{result.runtime}ms - #{describe(result.test)}" }.join("\n")}
          SLOW
        ].compact.join("\n\n")

        after_suite tldr_config, test_results
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
          "#{describe(result.test, result.relevant_location)}:",
          result.error.message.chomp,
          <<~RERUN.chomp,

            Re-run this test:
              #{"bundle exec " if defined?(Bundler)}tldr #{result.test.location.relative} #{config.to_single_args}
          RERUN
          (TLDR.filter_backtrace(result.error.backtrace).join("\n") if config.verbose)
        ].compact.reject(&:empty?).join("\n").strip
      end

      def describe(test, location = test.location)
        "#{test.klass}##{test.method} [#{location.relative}]"
      end
    end
  end
end
