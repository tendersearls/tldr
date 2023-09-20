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
        @suite_start_time = Process.clock_gettime Process::CLOCK_MONOTONIC, :microsecond
        @out.print <<~MSG
          Options: #{tldr_command} #{tldr_config.to_full_args}

          🏃 Running:

        MSG
      end

      def after_test result
        if result.passing?
          @out.print result.emoji
        else
          @err.print result.emoji
        end
      end

      def time_diff start, stop = Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)
        ((stop - start) / 1000.0).round
      end

      def after_tldr tldr_config, planned_tests, wip_tests, test_results
        stop_time = Process.clock_gettime Process::CLOCK_MONOTONIC, :microsecond

        @err.print "🥵"
        @err.print "\n\n"
        wrap_in_horizontal_rule do
          @err.print [
            "too long; didn't run!",
            "🏃 Completed #{test_results.size} of #{planned_tests.size} tests (#{((test_results.size.to_f / planned_tests.size) * 100).round}%) before running out of time.",
            (<<~WIP.chomp if wip_tests.any?),
              🙅 #{plural wip_tests.size, "test was", "tests were"} cancelled in progress:
              #{wip_tests.map { |wip_test| "  #{time_diff(wip_test.start_time, stop_time)}ms - #{describe(wip_test.test)}" }.join("\n")}
            WIP
            (<<~SLOW.chomp if test_results.any?),
              🐢 Your #{[10, test_results.size].min} slowest completed tests:
              #{test_results.sort_by(&:runtime).last(10).reverse.map { |result| "  #{result.runtime}ms - #{describe(result.test)}" }.join("\n")}
            SLOW
            describe_tests_that_didnt_finish(tldr_config, planned_tests, test_results)
          ].compact.join("\n\n")
        end

        after_suite tldr_config, test_results
      end

      def after_fail_fast tldr_config, planned_tests, wip_tests, test_results, last_result
        unrun_tests = planned_tests - test_results.map(&:test) - wip_tests.map(&:test)

        @err.print "\n\n"
        wrap_in_horizontal_rule do
          @err.print [
            "Failing fast after #{describe(last_result.test, last_result.relevant_location)} #{last_result.error? ? "errored" : "failed"}.",
            ("#{plural wip_tests.size, "test was", "tests were"} cancelled in progress." if wip_tests.any?),
            ("#{plural unrun_tests.size, "test was", "tests were"} not run at all." if unrun_tests.any?)
          ].compact.join("\n\n")
        end

        after_suite tldr_config, test_results
      end

      def after_suite tldr_config, test_results
        duration = time_diff @suite_start_time
        summary = summarize tldr_config, test_results

        @out.print "\n\n"
        summary.each.with_index do |summary, index|
          @err.print "#{index + 1}) #{summary}\n\n"
        end

        @out.print "Finished in #{duration}ms."

        @out.print "\n\n"
        class_count = test_results.map { |result| result.test.class }.uniq.size
        test_count = test_results.size
        @out.print [
          plural(class_count, "test class", "test classes"),
          plural(test_count, "test method"),
          plural(test_results.count(&:failure?), "failure"),
          plural(test_results.count(&:error?), "error"),
          plural(test_results.count(&:skip?), "skip")
        ].join(", ")

        @out.print "\n"
      end

      private

      def summarize config, results
        results.reject { |result| result.error.nil? }
          .sort_by { |result| result.test.location.locator }
          .map { |result| summarize_result config, result }
      end

      def summarize_result config, result
        [
          "#{result.type.to_s.capitalize}:",
          "#{describe(result.test, result.relevant_location)}:",
          result.error.message.chomp,
          <<~RERUN.chomp,

            Re-run this test:
              #{tldr_command} #{config.to_single_path_args(result.test.location.locator)}
          RERUN
          (TLDR.filter_backtrace(result.error.backtrace).join("\n") if config.verbose)
        ].compact.reject(&:empty?).join("\n").strip
      end

      def describe test, location = test.location
        "#{test.klass}##{test.method} [#{location.locator}]"
      end

      def plural count, singular, plural = "#{singular}s"
        "#{count} #{(count == 1) ? singular : plural}"
      end

      def wrap_in_horizontal_rule
        rule = "🚨" + "=" * 20 + " ABORTED RUN " + "=" * 20 + "🚨"
        @err.print "#{rule}\n\n"
        yield
        @err.print "\n\n#{rule}"
      end

      def describe_tests_that_didnt_finish config, planned_tests, test_results
        tests = planned_tests - test_results.map(&:test)
        return if tests.empty?

        test_locators = tests.group_by(&:file).map { |_, tests|
          "#{tests.first.location.relative}:#{tests.map(&:line).sort.join(":")}"
        }.uniq
        <<~MSG
          🤘 Run the #{plural tests.size, "test"} that didn't finish:
            #{tldr_command} #{config.to_full_args exclude: [:paths]} #{test_locators.join(" \\\n    ")}
        MSG
      end

      def tldr_command
        "#{"bundle exec " if defined?(Bundler)}tldr"
      end
    end
  end
end
