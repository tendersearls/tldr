class TLDR
  class Strategizer
    Strategy = Struct.new :tests, :tests_and_groups

    # Combine all discovered test methods with any methods grouped by run_these_together!
    #
    # Priorities:
    #   - Map over tests to build out groups in order to retain shuffle order
    #     (group will run in position of first test in the group)
    #   - If a test is in multiple groups, only run it once
    def strategize tests, grouped_tests
      already_included_groups = []

      Strategy.new tests, tests.map { |test|
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
    end
  end
end
