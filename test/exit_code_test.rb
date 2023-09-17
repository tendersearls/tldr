require "test_helper"

class ExitCodeTest < Minitest::Test
  def test_success
    result = TLDRunner.should_succeed("success.rb")

    assert_equal "", result.stderr
    assert_equal 0, result.exit_code
    assert_equal "💯", result.stdout
  end

  def test_failure
    result = TLDRunner.should_fail("fail.rb")

    assert_equal "🙏", result.stderr
    assert_equal 1, result.exit_code
    assert_equal "", result.stdout
  end
end
