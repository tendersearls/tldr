require "irb"
require "concurrent"

class TLDR
  class Runner
    def initialize
      @results = Concurrent::Array.new
    end

    def run config, plan
      @results.clear

      time_bomb = Thread.new {
        sleep 1.8

        # Don't hard-kill the runner if user is debugging, it'll
        # screw up their terminal slash be a bad time
        while IRB.CurrentContext
          sleep 1
        end

        config.reporter.after_tldr(config, plan.tests, @results.dup)
        exit! 3
      }

      parallelize(plan.tests, config.workers) { |test|
        e = nil
        runtime = time_it do
          instance = test.klass.new
          instance.setup if instance.respond_to? :setup
          instance.send(test.method)
          instance.teardown if instance.respond_to? :teardown
        rescue SkipTest, Assertions::Failure, StandardError => e
        end
        TestResult.new(test, e, runtime).tap do |result|
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
          group.map { |test|
            blk.call(test).tap do |result|
              @results << result
            end
          }
        }
      }.flat_map(&:value)
    end

    def time_it
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)
      yield
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond) - start) / 1000.0).round
    end
  end
end
