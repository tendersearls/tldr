class Super < TLDR
  run_these_together!

  @@nonsense = 0

  def teardown
    @@nonsense = 0
  end
end

class TA1 < Super
  def test_1
    @@nonsense += 1
    sleep 0.1
    assert_equal 1, @@nonsense
  end
end

class TB2 < Super
  def test_1
    @@nonsense += 1
    sleep 0.1
    assert_equal 1, @@nonsense
  end
end
