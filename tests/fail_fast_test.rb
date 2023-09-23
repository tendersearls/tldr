require "test_helper"

class ExitCodeTest < Minitest::Test
  def test_fails_fast
    result = TLDRunner.should_fail "fail_fast.rb", "--seed 1 --fail-fast --workers 3"

    assert_includes result.stdout, "😡"
    assert_includes result.stderr, "Failing fast after FailFast#test_fail [tests/fixture/fail_fast.rb:4] failed."
    assert_includes result.stderr, "1 test was cancelled in progress."
    assert_includes result.stderr, "2 tests were not run at all."
    refute_includes result.stdout, "😁"
  end
end
