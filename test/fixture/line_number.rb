class LineNumber < TLDR
  def test_some_line
    assert true
  end

  def test_some_other_line
    skip
  end

  def test_some_third_line
    assert false
  end
end
