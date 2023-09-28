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

class Super < TLDR
  dont_run_these_in_parallel!
end

class SubTA < Super
  def test_1
    Clock.change!(Time.parse("2080-01-01 12:00:00 UTC")) do
      sleep 0.01
      assert_equal 2080, Clock.now.year
    end
  end
end

class SubTB < Super
  def test_1
    Clock.change!(Time.parse("2070-01-01 12:00:00 UTC")) do
      sleep 0.01
      assert_equal 2070, Clock.now.year
    end
  end
end
