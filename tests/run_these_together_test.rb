require "test_helper"

class RunTheseTogetherTest < Minitest::Test
  def test_running_these_together
    result = TLDRunner.should_succeed "run_these_together.rb"

    assert_includes result.stdout, "6 test methods"
  end
end
