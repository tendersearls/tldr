class TLDR
  class Parallelizer
    def initialize
      @strategizer = Strategizer.new
    end

    def parallelize tests, parallel, &blk
      return tests.map(&blk) if tests.size < 2 || !parallel
      tldr_pool = Concurrent::ThreadPoolExecutor.new(
        name: "tldr",
        auto_terminate: true
      )

      strategy = @strategizer.strategize tests, GROUPED_TESTS

      strategy.tests_and_groups.map { |test_or_group|
        tests_to_run = if test_or_group.group?
          test_or_group.tests.select { |test| tests.include? test }
        else
          [test_or_group]
        end

        unless tests_to_run.empty?
          Concurrent::Promises.future_on(tldr_pool) {
            tests_to_run.map(&blk)
          }
        end
      }.compact.flat_map(&:value)
    end

    private

    def substitute_tests_grouped_by_run_these_together! tests
    end
  end
end
