require "test_helper"

class HooksTest < Minitest::Test
  def test_hooks
    result = TLDRunner.should_succeed "hooks.rb", "--no-parallel"

    assert_includes result.stdout, <<~MSG
      ABC😁
      ABC😁
    MSG
  end
end
