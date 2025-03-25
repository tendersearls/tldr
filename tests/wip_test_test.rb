require "test_helper"

class WipTestTest < Minitest::Test
  class SomeTest < TLDR
    def test_a
    end
  end

  def test_backtrace_at_exit
    test_a = TLDR::Test.new(SomeTest, :test_a)
    wip_test = TLDR::WIPTest.new(test_a, Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond) - 1_800_000)

    test_thread = Thread.new(name: "test_thread") {
      wip_test.thread = Thread.current
      loop { sleep 0.001 }
    }
    sleep 0.001 until wip_test.thread

    assert_nil wip_test.backtrace_at_exit

    wip_test.capture_backtrace_at_exit
    test_thread.exit

    if TLDR::RubyUtil.parsing_with_prism?
      assert_match("wip_test_test.rb:15:in 'Kernel#sleep'", wip_test.backtrace_at_exit[0])
      assert_match(":in 'block (2 levels) in WipTestTest#test_backtrace_at_exit'", wip_test.backtrace_at_exit[1])
      assert_match(":in 'Kernel#loop'", wip_test.backtrace_at_exit[2])
      assert_match(":in 'block in WipTestTest#test_backtrace_at_exit'", wip_test.backtrace_at_exit[3])
    else
      assert_match("wip_test_test.rb:15:in `sleep'", wip_test.backtrace_at_exit[0])
      assert_match(":in `block (2 levels) in test_backtrace_at_exit'", wip_test.backtrace_at_exit[1])
      assert_match(":in `loop'", wip_test.backtrace_at_exit[2])
      assert_match(":in `block in test_backtrace_at_exit'", wip_test.backtrace_at_exit[3])
    end
  end

  def test_backtrace_at_exit_without_thread
    test_a = TLDR::Test.new(SomeTest, :test_a)
    wip_test = TLDR::WIPTest.new(test_a, Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond) - 1_800_000)

    wip_test.capture_backtrace_at_exit

    assert_nil wip_test.backtrace_at_exit
  end
end
