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

  def test_timeout_with_exit_0_on_timeout_flag
    result = TLDRunner.run "slow.rb", "--no-parallel --timeout 0.001 --exit-0-on-timeout"

    assert_equal 0, result.exit_code
    assert_includes result.stderr, "too long; didn't run!"
    assert_includes result.stderr, "ABORTED RUN"
  end

  def test_timeout_without_exit_0_on_timeout_flag
    result = TLDRunner.run "slow.rb", "--no-parallel --timeout 0.001"

    assert_equal 3, result.exit_code
    assert_includes result.stderr, "too long; didn't run!"
    assert_includes result.stderr, "ABORTED RUN"
  end

  def test_timeout_with_failing_test_and_exit_0_on_timeout_flag
    result = TLDRunner.run ["fail.rb", "slow.rb"], "--timeout 0.01 --exit-0-on-timeout"

    # Even with --exit-0-on-timeout, test failures/errors should result in proper exit code
    assert_equal 1, result.exit_code  # 1 for failures
    assert_includes result.stderr, "ABORTED RUN"
    # Should have run at least one failing test before timing out
    assert_includes result.stderr, "Failing tests:"
  end

  def test_failure_with_exit_2_on_failure_flag
    result = TLDRunner.run "fail.rb", "--exit-2-on-failure"

    # With --exit-2-on-failure, failures should exit with code 2
    assert_equal 2, result.exit_code
    assert_includes result.stderr, "Failing tests:"
  end

  def test_timeout_with_failing_test_and_exit_2_on_failure_flag
    result = TLDRunner.run ["fail.rb", "slow.rb"], "--timeout 0.01 --exit-2-on-failure"

    # With --exit-2-on-failure, failures during timeout should exit with code 2
    assert_equal 2, result.exit_code
    assert_includes result.stderr, "ABORTED RUN"
    assert_includes result.stderr, "Failing tests:"
  end
end
