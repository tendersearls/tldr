require_relative "test_helper"

class RunTheseTogetherTest < Minitest::Test
  def test_running_these_together
    result = TLDRunner.should_succeed "run_these_together.rb"

    assert_includes result.stdout, "6 test methods"
  end

  def test_running_these_together_specified_by_superclass
    result = TLDRunner.should_succeed "run_these_together_superclasses.rb"

    assert_includes result.stdout, "2 test methods"
  end
end
