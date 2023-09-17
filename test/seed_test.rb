require "test_helper"

class SeedTest < Minitest::Test
  def test_order_1
    result = TLDRunner.should_succeed("seed.rb", seed: 1)

    assert_equal "", result.stderr
    assert_equal 0, result.exit_code
    assert_equal "💯🫥", result.stdout
  end

  def test_order_2
    result = TLDRunner.should_succeed("seed.rb", seed: 2)

    assert_equal "", result.stderr
    assert_equal 0, result.exit_code
    assert_equal "🫥💯", result.stdout
  end
end
