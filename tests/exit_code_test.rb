require_relative "test_helper"

class ExitCodeTest < Minitest::Test
  def test_success
    result = TLDRunner.should_succeed "success.rb"

    assert_equal "", result.stderr
    assert_equal 0, result.exit_code
    assert_includes result.stdout, "\n.\n"
    # Command shouldn't include --seed if it wasn't explicitly set
    assert_includes result.stdout, "Command: bundle exec tldr \"tests/fixture/success.rb\"\n"
    assert_match(/--seed \d+/, result.stdout)
  end

  def test_failure
    result = TLDRunner.should_fail "fail.rb"

    assert_includes result.stdout, "F"
    assert_includes result.stderr, <<~MSG.chomp
      Failing tests:

      1) FailTest#test_fails [tests/fixture/fail.rb:3] failed:
      Expected false to be truthy

        Re-run this test:
          bundle exec tldr "tests/fixture/fail.rb:2"
    MSG
    assert_equal 1, result.exit_code
  end

  def test_error
    result = TLDRunner.should_fail "error.rb"

    assert_includes result.stdout, "E"
    assert_includes result.stderr, <<~MSG.chomp
      Failing tests:

      1) ErrorTest#test_errors [tests/fixture/error.rb:3] errored:
      💥

        Re-run this test:
          bundle exec tldr "tests/fixture/error.rb:2"
    MSG
    assert_equal 2, result.exit_code
  end

  def test_skip
    result = TLDRunner.should_succeed "skip.rb"

    assert_includes result.stdout, <<~MSG
      Skipped tests:

        - SuccessTest#test_skips [tests/fixture/skip.rb:2]
    MSG
    assert_equal 0, result.exit_code
    assert_includes result.stdout, "S"
  end
end
