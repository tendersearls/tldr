require "irb"
require "concurrent"

class TLDR
  class Runner
    def initialize
      @wip = Concurrent::Array.new
      @results = Concurrent::Array.new
    end

    def run config, plan
      @wip.clear
      @results.clear

      time_bomb = Thread.new {
        sleep 1.8
        explode = proc do
          config.reporter.after_tldr config, plan.tests, @wip.dup, @results.dup
          exit! 3
        end

        # Don't hard-kill the runner if user is debugging, it'll
        # screw up their terminal slash be a bad time
        if IRB.CurrentContext
          IRB.conf[:AT_EXIT] << explode
        else
          explode.call
        end
      }

      parallelize(plan.tests, config.workers) { |test|
        e = nil
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)
        wip_test = WIPTest.new test, start_time
        @wip << wip_test
        runtime = time_it(start_time) do
          instance = test.klass.new
          instance.setup if instance.respond_to? :setup
          instance.send(test.method)
          instance.teardown if instance.respond_to? :teardown
        rescue Skip, Failure, StandardError => e
        end
        TestResult.new(test, e, runtime).tap do |result|
          @results << result
          @wip.delete wip_test
          config.reporter.after_test result
        end
      }.tap do
        time_bomb.kill
      end
    end

    private

    def parallelize tests, workers, &blk
      return tests.map(&blk) if tests.size < 2 || workers < 2

      group_size = (tests.size.to_f / workers).ceil
      tests.each_slice(group_size).map { |group|
        Concurrent::Promises.future {
          group.map(&blk)
        }
      }.flat_map(&:value)
    end

    def time_it(start)
      yield
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond) - start) / 1000.0).round
    end
  end
end
