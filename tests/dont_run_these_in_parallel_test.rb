require "test_helper"

class DontRunTheseInParallelTest < Minitest::Test
  def test_not_running_in_parallel
    result = TLDRunner.should_succeed "dont_run_these_in_parallel.rb"

    assert_includes result.stdout, "6 test methods"
  end

  def test_prepend_pushes_matching_tests_to_the_front
    result = TLDRunner.should_succeed "dont_run_these_in_parallel.rb", "-v --prepend tests/fixture/dont_run_these_in_parallel.rb:35"

    [
      "TA#test_1",
      "TB#test_1",
      "TB#test_2",
      "TC#test_1",
      "TC#test_2"
    ].each do |other|
      assert_strings_appear_in_this_order result.stdout, ["TA#test_2", other]
    end
  end

  def test_not_running_parallel_specified_by_superclass
    result = TLDRunner.should_succeed "dont_run_these_in_parallel_superclasses.rb"

    assert_includes result.stdout, "2 test methods"
  end
end
