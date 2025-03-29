class Emoji < TLDR
  def test_pass
  end

  def test_fail
    assert false
  end

  def test_error
    raise
  end

  def test_skip
    skip
  end
end
