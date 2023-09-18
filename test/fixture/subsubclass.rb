class SuperTest < TLDR
end

class SubTest < SuperTest
  def test_passes
    assert true
  end
end

class SubSubTest < SubTest
  def test_passes
    assert true
  end
end
