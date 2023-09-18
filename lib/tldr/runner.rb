require "irb"

class TLDR
  class Runner
    def run config, plan
      $stdout.sync = true
      $stderr.sync = true

      time_bomb = Thread.new {
        sleep 1.8

        # Don't hard-kill the runner if user is debugging, it'll
        # screw up their terminal slash be a bad time
        while IRB.CurrentContext
          sleep 1
        end

        config.reporter.after_tldr
        exit! 3
      }

      plan.tests.map { |test|
        begin
          instance = test.klass.new
          instance.send(test.method)
        rescue SkipTest, Assertions::Failure, StandardError => e
        end
        TestResult.new(test, e).tap do |result|
          config.reporter.after_test result
        end
      }.tap do
        time_bomb.kill
      end
    end
  end
end
