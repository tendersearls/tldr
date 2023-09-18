class Fails < TLDR
  def test_f1
    assert false
  end

  def test_f2
    assert_equal 1, 2
  end

  def test_f3
    assert_equal false, true
  end

  def test_f4
    assert_equal false, true, "false isn't true?!"
  end

  def test_s1
    skip
  end
end
