require "test_helper"

class ExitCodeTest < Minitest::Test
  def test_success
    result = TLDRunner.run("success.rb")

    assert_equal "", result.stderr
    assert_equal 0, result.exit_code
    assert_equal "💯", result.stdout
  end
  end
end
