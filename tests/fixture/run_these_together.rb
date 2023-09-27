class TA < TLDR
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

class TB < TLDR
  # The setup hook in TB will implicate both tests, but TC's dependency on
  # TB.woah is isolated to TC#test_2
  run_these_together! [
    [TB, nil],
    ["TC", :test_2]
  ]

  @@woah = 0
  def self.woah
    @@woah
  end

  def setup
    TB.woah = 0
  end

  def self.woah= woah
    @@woah = woah
  end

  def test_1
    TB.woah += 1
    sleep 0.1
    assert_equal 1, TB.woah
  end

  def test_2
  end
end

class TC < TLDR
  def teardown
  end

  def test_1
  end

  def test_2
    TB.woah += 1
    sleep 0.1
    assert_equal 1, TB.woah
    TB.woah = 0
  end
end
