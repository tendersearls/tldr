require_relative "test_helper"

class NoEmojiTest < Minitest::Test
  def test_no_emoji
    result = TLDRunner.should_fail "no_emoji.rb", "--seed 1 --no-emoji"

    refute_includes result.stdout, "🏃"
    assert_includes result.stdout, <<~MSG
      S.EF
    MSG
  end
end
