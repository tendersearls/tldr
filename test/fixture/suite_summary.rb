class T1 < TLDR
  def test_1_1
  end

  def test_1_2
    skip
  end

  def test_1_3
    assert false
  end

  def test_1_4
    raise "💥"
  end
end

class T2 < TLDR
  def test_2_1
  end

  def test_2_2
    skip
  end

  def test_2_3
    assert false
  end

  def test_2_4
    raise "💥"
  end
end
