class TA < TLDR
  # The setup hook in TA will implicate both tests, but the dependency in
  # TC is isolated to :test_2
  run_these_together! [
    [TA, nil],
    ["TC", :test_2]
  ]

  @@woah = 0
  def self.woah
    @@woah
  end

  def setup
    TA.woah = 0
  end

  def self.woah= woah
    @@woah = woah
  end

  def test_1
    TA.woah += 1
    sleep 0.1
    assert_equal 1, TA.woah
  end

  def test_2
  end
end

class TB < TLDR
  run_these_together!

  @@nonsense = 0

  def teardown
    @@nonsense = 0
  end

  def test_1
    @@nonsense += 1
    sleep 0.1
    assert_equal 1, @@nonsense
  end

  def test_2
    @@nonsense += 1
    sleep 0.1
    assert_equal 1, @@nonsense
  end
end

class TC < TLDR
  def teardown
  end

  def test_1
  end

  def test_2
    TA.woah += 1
    sleep 0.1
    assert_equal 1, TA.woah
    TA.woah = 0
  end
end
