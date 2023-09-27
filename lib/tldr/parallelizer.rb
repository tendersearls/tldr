class TLDR
  class Parallelizer
    def initialize
      @strategizer = Strategizer.new
      @thread_pool = Concurrent::ThreadPoolExecutor.new(
        name: "tldr",
        auto_terminate: true
      )
    end

    def parallelize all_tests, parallel, &blk
      return run_in_sequence(all_tests, &blk) if all_tests.size < 2 || !parallel

      strategy = @strategizer.strategize all_tests, GROUPED_TESTS, THREAD_UNSAFE_TESTS

      run_in_parallel(strategy.parallel_tests_and_groups, &blk) +
        run_in_sequence(strategy.thread_unsafe_tests, &blk)
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
