require_relative "test_helper"

class EmojiTest < Minitest::Test
  def test_emoji_disabled
    result = TLDRunner.should_fail "emoji.rb", "--seed 1 --no-emoji"

    refute_includes result.stdout, "🏃"
    assert_includes result.stdout, <<~MSG
      S.EF
    MSG
  end

  def test_emoji_enabled
    result = TLDRunner.should_fail "emoji.rb", "--seed 1 --emoji"

    assert_includes result.stdout, <<~MSG
      Command: bundle exec tldr --seed 1 --emoji "tests/fixture/emoji.rb"
      🌱 --seed 1

      🏃 Running:

      🫥😁🤬😡

      Skipped tests:

        - Emoji#test_skip [tests/fixture/emoji.rb:13]
    MSG
  end
end
