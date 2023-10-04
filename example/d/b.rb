class BTest < TLDR
  def test_b_1
    # Should be excluded
  end

  def test_b_2
    fail "wups"
  end
end
