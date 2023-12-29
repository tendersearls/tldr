require "test_helper"

class WipTestTest < Minitest::Test
  class SomeTest < TLDR
    def test_a
    end
  end

  def test_backtrace_at_exit
    test_a = TLDR::Test.new(SomeTest, :test_a)
    wip_test = TLDR::WIPTest.new(test_a, Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond) - 1_800_000)

    sleep_line = nil
    test_thread = Thread.new(name: "test_thread") {
      wip_test.thread = Thread.current
      sleep_line = __LINE__ + 1
      loop { sleep 0.001 }
    }
    sleep 0.001 until wip_test.thread

    assert_nil wip_test.backtrace_at_exit

    wip_test.capture_backtrace_at_exit
    test_thread.exit

    assert_equal [
      "#{__FILE__}:#{sleep_line}:in `sleep'",
      "#{__FILE__}:#{sleep_line}:in `block (2 levels) in test_backtrace_at_exit'",
      "#{__FILE__}:#{sleep_line}:in `loop'",
      "#{__FILE__}:#{sleep_line}:in `block in test_backtrace_at_exit'"
    ], wip_test.backtrace_at_exit
  end

  def test_backtrace_at_exit_without_thread
    test_a = TLDR::Test.new(SomeTest, :test_a)
    wip_test = TLDR::WIPTest.new(test_a, Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond) - 1_800_000)

    wip_test.capture_backtrace_at_exit

    assert_nil wip_test.backtrace_at_exit
  end
end
