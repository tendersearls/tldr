require "time"

# Clock is a global resource like Time, but can be set and reset by any test
class Clock
  @@time = nil
  def self.now
    @@time || Time.now
  end

  def self.change! time
    @@time = time
    if block_given?
      yield
      reset!
    end
  end

  def self.reset!
    @@time = nil
  end
end

class TA < TLDR
  dont_run_these_in_parallel!

  def test_1
    Clock.change!(Time.parse("2080-01-01 12:00:00 UTC")) do
      sleep 0.01
      assert_equal 2080, Clock.now.year
    end
  end

  def test_2
    Clock.change!(Time.parse("2070-01-01 12:00:00 UTC")) do
      sleep 0.01
      assert_equal 2070, Clock.now.year
    end
  end
end

class TB < TLDR
  # dont_run_these_in_parallel! can specify any test identifiers as
  # (class, method) tuples, not just in one's own class
  dont_run_these_in_parallel! [
    [TB, :test_1],
    ["TC", :test_2]
  ]

  def test_1
    Clock.change!(Time.parse("2060-01-01 12:00:00 UTC")) do
      sleep 0.01
      assert_equal 2060, Clock.now.year
    end
  end

  def test_2
    assert_equal Time.now.year, Clock.now.year
  end
end

class TC < TLDR
  def test_1
    assert_equal Time.now.hour, Clock.now.hour
  end

  def test_2
    Clock.change!(Time.parse("2050-01-01 12:00:00 UTC")) do
      sleep 0.01
      assert_equal 2050, Clock.now.year
    end
  end
end
