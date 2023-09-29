class TLDR
  class Executor
    def initialize
      @thread_pool = Concurrent::ThreadPoolExecutor.new(
        name: "tldr",
        auto_terminate: true
      )
    end

    def execute strategy, &blk
      if strategy.parallel?
        run_in_sequence(strategy.prepend_sequential_tests, &blk) +
          run_in_parallel(strategy.parallel_tests_and_groups, &blk) +
          run_in_sequence(strategy.append_sequential_tests, &blk)
      else
        run_in_sequence(strategy.all_tests, &blk)
      end
    end

    private

    def run_in_sequence tests, &blk
      tests.map(&blk)
    end

    def run_in_parallel tests_and_groups, &blk
      tests_and_groups.map { |test_or_group|
        tests_to_run = if test_or_group.group?
          test_or_group.tests
        else
          [test_or_group]
        end

        unless tests_to_run.empty?
          Concurrent::Promises.future_on(@thread_pool) {
            tests_to_run.map(&blk)
          }
        end
      }.compact.flat_map(&:value)
    end
  end
end
