require_relative "test_helper"

class SeedTest < Minitest::Test
  def test_order_1
    result = TLDRunner.should_succeed "seed.rb", "--seed 1"

    assert_includes result.stdout, <<~MSG
      Skipped tests:

        - SeedTest#test_skip [tests/fixture/seed.rb:6]
    MSG
    assert_equal 0, result.exit_code
    assert_includes result.stdout, "--seed 1"
    assert_includes result.stdout, "🫥😁"
  end

  def test_order_2
    result = TLDRunner.should_succeed "seed.rb", "--seed 2"

    assert_includes result.stdout, <<~MSG
      Skipped tests:

        - SeedTest#test_skip [tests/fixture/seed.rb:6]
    MSG
    assert_equal 0, result.exit_code
    assert_includes result.stdout, "--seed 2"
    assert_includes result.stdout, "😁🫥"
  end
end
