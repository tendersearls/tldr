class SuccessTest < TLDR
  def test_skips
    skip

    assert false
  end
end
