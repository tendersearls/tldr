require "test_helper"

class ExitCodeTest < Minitest::Test
  def test_success
    result = TLDRunner.should_succeed("success.rb")

    assert_equal "", result.stderr
    assert_equal 0, result.exit_code
    assert_includes result.stdout, "😁"
  end

  def test_failure
    result = TLDRunner.should_fail("fail.rb")

    assert_includes result.stderr, "😡"
    assert_includes result.stderr, <<~MSG
      1) Failure:
      FailTest#test_fails [test/fixture/fail.rb:3]:
      Expected false to be truthy.

      Re-run this test:
        bundle exec tldr test/fixture/fail.rb:2
    MSG
    assert_equal 1, result.exit_code
  end

  def test_error
    result = TLDRunner.should_fail("error.rb")

    assert_includes result.stderr, "🤬"
    assert_includes result.stderr, <<~MSG
      1) Error:
      ErrorTest#test_errors [test/fixture/error.rb:3]:
      💥

      Re-run this test:
        bundle exec tldr test/fixture/error.rb:2
    MSG
    assert_equal 2, result.exit_code
  end

  def test_skip
    result = TLDRunner.should_succeed("skip.rb")

    assert_includes result.stderr, <<~MSG
      1) Skip:
      SuccessTest#test_skips [test/fixture/skip.rb:3]:

      Re-run this test:
        bundle exec tldr test/fixture/skip.rb:2
    MSG
    assert_equal 0, result.exit_code
    assert_includes result.stdout, "🫥"
  end
end
