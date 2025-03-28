require "irb"

class TLDR
  class Runner
    def initialize
      @executor = Executor.new
      @wip = Concurrent::Array.new
      @results = Concurrent::Array.new
      @run_aborted = Concurrent::AtomicBoolean.new(false)
    end

    def run config, plan
      @wip.clear
      @results.clear
      reporter = config.reporter.new(config)
      reporter.before_suite(plan.tests)

      time_bomb = Thread.new {
        next if config.timeout < 0

        explode = proc do
          next if @run_aborted.true?
          @run_aborted.make_true
          @wip.each(&:capture_backtrace_at_exit)
          reporter.after_tldr(plan.tests, @wip.dup, @results.dup)
          exit!(3)
        end

        sleep(config.timeout)

        # Don't hard-kill the runner if user is debugging, it'll
        # screw up their terminal slash be a bad time
        if IRB.CurrentContext
          IRB.conf[:AT_EXIT] << explode
        else
          explode.call
        end
      }

      results = @executor.execute(plan) { |test|
        run_test(test, config, plan, reporter)
      }.tap do
        time_bomb.kill
      end

      unless @run_aborted.true?
        reporter.after_suite(results)
        exit(exit_code(results))
      end
    end

    private

    def run_test test, config, plan, reporter
      e = nil
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)
      wip_test = WIPTest.new(test, start_time, Thread.current)
      @wip << wip_test
      runtime = time_it(start_time) do
        instance = test.test_class.new
        instance.setup if instance.respond_to?(:setup)
        if instance.respond_to?(:around)
          did_run = false
          instance.around {
            did_run = true
            instance.send(test.method_name)
          }
          raise Error, "#{test.test_class}#around failed to yield or call the passed test block" unless did_run
        else
          instance.send(test.method_name)
        end
        instance.teardown if instance.respond_to?(:teardown)
      rescue Skip, Failure, StandardError => e
      end
      TestResult.new(test, e, runtime).tap do |result|
        next if @run_aborted.true?
        @results << result
        @wip.delete(wip_test)
        reporter.after_test(result)
        fail_fast(reporter, plan, result) if result.failing? && config.fail_fast
      end
    end

    def fail_fast reporter, plan, fast_failed_result
      unless @run_aborted.true?
        @run_aborted.make_true
        abort = proc do
          reporter.after_fail_fast(plan.tests, @wip.dup, @results.dup, fast_failed_result)
          exit!(exit_code([fast_failed_result]))
        end

        if IRB.CurrentContext
          IRB.conf[:AT_EXIT] << abort
        else
          abort.call
        end
      end
    end

    def time_it start
      yield
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond) - start) / 1000.0).round
    end

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
