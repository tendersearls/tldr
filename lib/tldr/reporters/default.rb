class TLDR
  module Reporters
    class Default < Base
      def initialize config, out = $stdout, err = $stderr
        super
        @icons = @config.no_emoji ? IconProvider::Base.new : IconProvider::Emoji.new
      end

      def before_suite tests
        clear_screen_if_being_watched!
        @suite_start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)
        @out.print <<~MSG
          Command: #{tldr_command} #{@config.to_full_args}
          #{@icons.seed} #{CONFLAGS[:seed]} #{@config.seed}

          #{@icons.run} Running:

        MSG
      end

      def after_test result
        output = case result.type
        when :success then @icons.success
        when :skip then @icons.skip
        when :failure then @icons.failure
        when :error then @icons.error
        end
        if @config.verbose
          @out.puts "#{output} #{result.type.capitalize} - #{describe(result.test, result.relevant_location)}"
        else
          @out.print output
        end
      end

      def after_tldr planned_tests, wip_tests, test_results
        stop_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)

        @out.print @icons.tldr
        @err.print "\n\n"

        if @config.yes_i_know
          @err.print "🚨 TLDR after completing #{test_results.size} of #{planned_tests.size} tests! Print full summary by omitting --yes-i-know"
        else
          wrap_in_horizontal_rule do
            @err.print [
              "too long; didn't run!",
              "#{@icons.run} Completed #{test_results.size} of #{planned_tests.size} tests (#{((test_results.size.to_f / planned_tests.size) * 100).round}%) before running out of time.",
              (<<~WIP.chomp if wip_tests.any?),
                #{@icons.wip} #{plural(wip_tests.size, "test was", "tests were")} cancelled in progress:
                #{wip_tests.map { |wip_test| "  #{time_diff(wip_test.start_time, stop_time)}ms - #{describe(wip_test.test)}" }.join("\n")}
              WIP
              (<<~SLOW.chomp if test_results.any?),
                #{@icons.slow} Your #{[10, test_results.size].min} slowest completed tests:
                #{test_results.sort_by(&:runtime).last(10).reverse.map { |result| "  #{result.runtime}ms - #{describe(result.test)}" }.join("\n")}
              SLOW
              describe_tests_that_didnt_finish(planned_tests, test_results),
              "🙈 Suppress this summary with --yes-i-know"
            ].compact.join("\n\n")
          end
        end

        after_suite(test_results)
      end

      def after_fail_fast planned_tests, wip_tests, test_results, last_result
        unrun_tests = planned_tests - test_results.map(&:test) - wip_tests.map(&:test)

        @err.print "\n\n"
        wrap_in_horizontal_rule do
          @err.print [
            "Failing fast after #{describe(last_result.test, last_result.relevant_location)} #{last_result.error? ? "errored" : "failed"}.",
            ("#{@icons.wip} #{plural(wip_tests.size, "test was", "tests were")} cancelled in progress." if wip_tests.any?),
            ("#{@icons.not_run} #{plural(unrun_tests.size, "test was", "tests were")} not run at all." if unrun_tests.any?),
            describe_tests_that_didnt_finish(planned_tests, test_results)
          ].compact.join("\n\n")
        end

        after_suite(test_results)
      end

      def after_suite test_results
        duration = time_diff(@suite_start_time)
        test_results = test_results.sort_by { |result| [result.test.location.file, result.test.location.line] }

        @err.print summarize_failures(test_results).join("\n\n")

        @out.print summarize_skips(test_results).join("\n")

        @out.print "\n\n"
        @out.print "Finished in #{duration}ms."

        @out.print "\n\n"
        class_count = test_results.uniq { |result| result.test.test_class }.size
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

      def time_diff start, stop = Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)
        ((stop - start) / 1000.0).round
      end

      def summarize_failures results
        failures = results.select { |result| result.failing? }
        return failures if failures.empty?

        ["\n\nFailing tests:"] + failures.map.with_index { |result, i| summarize_result(result, i) }
      end

      def summarize_result result, index
        [
          "#{index + 1}) #{describe(result.test, result.relevant_location)} #{result.failure? ? "failed" : "errored"}:",
          result.error.message.chomp,
          "\n  Re-run this test:",
          "    #{tldr_command} #{@config.to_single_path_args(result.test.location.locator, exclude_dotfile_matches: true)}\n",
          (TLDR.filter_backtrace(result.error.backtrace).join("\n") if @config.verbose)
        ].compact.reject(&:empty?).join("\n").strip
      end

      def summarize_skips results
        skips = results.select { |result| result.skip? }
        return skips if skips.empty?

        ["\n\nSkipped tests:\n"] + skips.map { |result| "  - #{describe(result.test)}" }
      end

      def describe test, location = test.location
        "#{test.test_class}##{test.method_name} [#{location.locator}]"
      end

      def plural count, singular, plural = "#{singular}s"
        "#{count} #{(count == 1) ? singular : plural}"
      end

      def wrap_in_horizontal_rule
        rule = @icons.alarm + "=" * 20 + " ABORTED RUN " + "=" * 20 + @icons.alarm
        @err.print "#{rule}\n\n"
        yield
        @err.print "\n\n#{rule}"
      end

      def describe_tests_that_didnt_finish planned_tests, test_results
        unrun = planned_tests - test_results.map(&:test)
        return if unrun.empty?

        unrun_locators = consolidate(unrun)
        failed = test_results.select(&:failing?).map(&:test)
        failed_locators = consolidate(failed, exclude: unrun_locators)
        suggested_locators = unrun_locators + [
          ("--comment \"Also include #{plural(failed.size, "test")} that failed:\"" if failed_locators.any?)
        ].compact + failed_locators
        <<~MSG
          #{@icons.rock_on} Run the #{plural(unrun.size, "test")} that didn't finish:
            #{tldr_command} #{@config.to_full_args(exclude: [:paths], exclude_dotfile_matches: true)} #{suggested_locators.join(" \\\n    ")}
        MSG
      end

      def consolidate tests, exclude: []
        tests.group_by(&:file).map { |_, tests|
          "\"#{tests.first.location.relative}:#{tests.map(&:line).uniq.sort.join(":")}\""
        }.uniq - exclude
      end

      def tldr_command
        "#{"bundle exec " if defined?(Bundler)}tldr"
      end

      def clear_screen_if_being_watched!
        if @config.i_am_being_watched
          @out.print "\e[2J\e[f"
        end
      end
    end
  end
end
