class TLDR
  GROUPED_TESTS = Concurrent::Array.new

  # If it's not safe to run a set of tests in parallel, you can force them to
  # run in a group together (in a single worker) with `run_these_together!` in
  # your test.
  #
  # This method takes an array of tuples, where the first element is the class
  # (or its name as a string, if the class is not yet defined in the current
  # file) and the second element is the method name. If the second element is
  # nil, then all the tests on the class will be run together.
  #
  # Examples:
  #   - `run_these_together!` will run all the tests defined on the current
  #     class to be run in a group
  #   - `run_these_together!([[ClassA, nil], ["ClassB", :test_1], [ClassB, :test_2]])`
  #    will run all the tests defined on ClassA, and test_1 and test_2 from ClassB
  #   (nil in the second position means "all the tests on this class")
  #
  def self.run_these_together! klass_method_tuples = [[self, nil]]
    GROUPED_TESTS << TestGroup.new(klass_method_tuples)
  end
end
