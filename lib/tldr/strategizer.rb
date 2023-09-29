class TLDR
  class Strategizer
    Strategy = Struct.new :parallel?, :all_tests, :prepend_sequential_tests,
      :parallel_tests_and_groups, :append_sequential_tests,
      keyword_init: true

    # Combine all discovered test methods with any methods grouped by run_these_together!
    #
    # Priorities:
    #   - Map over tests to build out groups in order to retain shuffle order
    #     (group will run in position of first test in the group)
    #   - If a test is in multiple groups, only run it once
    def strategize all_tests, run_these_together_groups, thread_unsafe_test_groups, config
      return Strategy.new(parallel?: false, all_tests:) if run_sequentially?(all_tests, config)

      thread_unsafe_tests, thread_safe_tests = partition_unsafe(all_tests, thread_unsafe_test_groups)
      prepend_sequential_tests, append_sequential_tests = partition_prepend(thread_unsafe_tests, config)

      grouped_tests = prepare_run_together_groups run_these_together_groups, thread_safe_tests, append_sequential_tests
      already_included_groups = []
      parallel_tests_and_groups = thread_safe_tests.map { |test|
        if (group = grouped_tests.find { |group| group.tests.include? test })
          if already_included_groups.include? group
            next
          elsif (other = already_included_groups.find { |other| (group.tests & other.tests).any? })
            other.tests |= group.tests
            next
          else
            already_included_groups << group
            group
          end
        else
          test
        end
      }.compact
      Strategy.new(
        parallel?: true,
        all_tests:,
        prepend_sequential_tests:,
        parallel_tests_and_groups:,
        append_sequential_tests:
      )
    end

    private

    def run_sequentially? all_tests, config
      all_tests.size < 2 || !config.parallel
    end

    def partition_unsafe tests, thread_unsafe_test_groups
      tests.partition { |test|
        thread_unsafe_test_groups.any? { |group| group.tests.include? test }
      }
    end

    # Sadly duplicative with Planner.rb, necessitating the extraction of PathUtil
    # Suboptimal, but we do indeed need to do this work in two places ¯\_(ツ)_/¯
    def partition_prepend thread_unsafe_tests, config
      prepend_paths = config.no_prepend ? [] : config.prepend_paths
      locations = PathUtil.expand_paths prepend_paths

      thread_unsafe_tests.partition { |test|
        PathUtil.locations_include_test? locations, test
      }
    end

    def prepare_run_together_groups run_these_together_groups, thread_safe_tests, thread_unsafe_tests
      grouped_tests = run_these_together_groups.map(&:dup)

      grouped_tests.each do |group|
        group.tests = group.tests.select { |test|
          thread_safe_tests.include?(test) && !thread_unsafe_tests.include?(test)
        }
      end

      grouped_tests.reject { |group| group.tests.size < 2 }
    end
  end
end
