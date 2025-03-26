require_relative "../../test_helper"

class FakeTest < TLDR
  def test_something
    assert_equal 1, 2
  end
end

class TestTest < Minitest::Test
  def test_end_line
    test = TLDR::Test.new(FakeTest, :test_something)
    refute test.covers_line?(3)
    assert test.covers_line?(4)
    assert test.covers_line?(5)
    assert test.covers_line?(6)
    refute test.covers_line?(7)
  end
end
