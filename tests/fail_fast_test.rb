require_relative "test_helper"

class FailFastTest < Minitest::Test
  def test_fails_fast
    result = TLDRunner.should_fail "fail_fast.rb", "--seed 9 --fail-fast --emoji"

    assert_includes result.stdout, "😁"
    assert_includes result.stdout, "😡"
    assert_includes result.stderr, "Failing fast after FailFast#test_fail [tests/fixture/fail_fast.rb:4] failed."
    assert_includes result.stderr, "1 test was not run at all."

    # Disabled this assertion b/c we no longer have a black-box way to starve worker threads so as to force this easily:
    # assert_includes result.stderr, "1 test was cancelled in progress."
  end
end
