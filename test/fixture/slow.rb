# Designed to be run with: tldr --seed 1 "test/fixture/slow.rb"
class Slow < TLDR
  def test_one
    zzz
  end

  def test_two
    zzz
  end

  def test_three
    zzz
    skip
  end

  def test_four
    zzz
  end

  def test_five
    zzz
    assert_equal 1, 2
  end

  def test_six
    zzz
    raise "💥"
  end

  def test_seven
    zzz
  end

  def test_eight
    zzz
  end

  private

  def zzz
    sleep 0.4
  end
end
