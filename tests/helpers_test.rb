require_relative "test_helper"

class HelpersTest < Minitest::Test
  def test_helpers
    result = TLDRunner.should_succeed "success.rb", "--helper tests/fixture/helper_b.rb --helper tests/fixture/helper_a.rb"

    assert_includes result.stdout, <<~MSG
      Helper B
      Helper A
    MSG
  end

  def test_helpers_glob
    result = TLDRunner.should_succeed "success.rb", "--helper \"tests/fixture/helper_*.rb\""

    assert_includes result.stdout, "Helper A"
    assert_includes result.stdout, "Helper B"
  end
end
