require "test_helper"

class DontRunTheseInParallelTest < Minitest::Test
  def test_running_these_together
    result = TLDRunner.should_succeed "dont_run_these_in_parallel.rb"

    assert_includes result.stdout, "6 test methods"
  end
end
