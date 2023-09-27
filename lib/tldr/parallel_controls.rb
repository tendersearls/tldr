class TLDR
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
  #
  GROUPED_TESTS = Concurrent::Array.new
  def self.run_these_together! klass_method_tuples = [[self, nil]]
    GROUPED_TESTS << TestGroup.new(klass_method_tuples)
  end

  # This is a similar API to run_these_together! but its effect is more drastic
  # Rather than running the provided (class, method) tuples in a group within a
  # thread as part of a parallel run, it will reserve all tests specified by
  # all calls to `dont_run_these_in_parallel!` to be run after all parallel tests have
  # finished.
  #
  # This has an important implication! If your test suite is over TLDR's time
  # limit, it means that these tests will never be run outside of CI unless you
  # run them manually.
  #
  # Like `run_these_together!`, `dont_run_these_in_parallel!` takes an array of
  # tuples, where the first element is the class (or its fully-qualified name as
  # a string) and the second element is `nil` (matching all the class's test
  # methods) or else one of the methods on the class.
  #
  # Examples:
  #   - `dont_run_these_in_parallel!` will run all the tests defined on the current
  #     class after all parallel tests have finished
  #   - `dont_run_these_in_parallel!([[ClassA, nil], ["ClassB", :test_1], [ClassB, :test_2]])`
  #    will run all the tests defined on ClassA, and test_1 and test_2 from ClassB
  #
  THREAD_UNSAFE_TESTS = Concurrent::Array.new
  def self.dont_run_these_in_parallel! klass_method_tuples = [[self, nil]]
    THREAD_UNSAFE_TESTS << TestGroup.new(klass_method_tuples)
  end
end
