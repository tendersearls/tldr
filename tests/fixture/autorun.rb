require "tldr/autorun"

class FruitTest < TLDR
  FRUIT = %w[🍌 🍎 🍊 🍈].freeze

  def test_banana
    assert_includes FRUIT, "🍌"
  end

  def test_orange
    assert_includes FRUIT, "🍊"
  end

  def test_peach
    refute_includes FRUIT, "🍑"
  end
end
