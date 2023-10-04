require "test_helper"

class DefaultReporterTest < Minitest::Test
  class SomeTest < TLDR
    def test_a
    end

    def test_b
    end

    def test_c
    end
  end

  def setup
    @io = SillyIO.new
  end

  def test_parallel_output
    config = TLDR::Config.new(seed: 42)
    subject = TLDR::Reporters::Default.new(config, @io, @io)
    test_a = TLDR::Test.new(SomeTest, :test_a)
    test_b = TLDR::Test.new(SomeTest, :test_b)
    test_c = TLDR::Test.new(SomeTest, :test_c)
    test_a_result = TLDR::TestResult.new(test_a, nil, 500)
    test_b_wip = TLDR::WIPTest.new(test_b, Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond) - 1_800_000)

    subject.before_suite([test_a])
    assert_equal <<~MSG, @io.string
      Command: bundle exec tldr --seed 42
      🌱 --seed 42

      🏃 Running:

    MSG
    @io.clear

    subject.after_test(test_a_result)
    assert_equal "😁", @io.string
    @io.clear

    subject.after_tldr [test_a, test_b, test_c], [test_b_wip], [test_a_result]
    assert_equal <<~MSG, scrub_time(@io.string)
      🥵

      🚨==================== ABORTED RUN ====================🚨

      too long; didn't run!

      🏃 Completed 1 of 3 tests (33%) before running out of time.

      🙅 1 test was cancelled in progress:
        XXXms - DefaultReporterTest::SomeTest#test_b [tests/default_reporter_test.rb:8]

      🐢 Your 1 slowest completed tests:
        XXXms - DefaultReporterTest::SomeTest#test_a [tests/default_reporter_test.rb:5]

      🤘 Run the 2 tests that didn't finish:
        bundle exec tldr --seed 42 "tests/default_reporter_test.rb:8:11"


      🙈 Suppress this summary with --yes-i-know

      🚨==================== ABORTED RUN ====================🚨

      Finished in XXXms.

      1 test class, 1 test method, 0 failures, 0 errors, 0 skips
    MSG
    @io.clear

    # Warning! Mutating config because lazy.
    config.yes_i_know = true
    subject.after_tldr [test_a, test_b, test_c], [test_b_wip], [test_a_result]
    assert_equal <<~MSG, scrub_time(@io.string)
      🥵

      🚨 TLDR! Display summary by omitting --yes-i-know

      Finished in XXXms.

      1 test class, 1 test method, 0 failures, 0 errors, 0 skips
    MSG
  end

  private

  def scrub_time(string)
    string.gsub(/(\d+)ms/, "XXXms")
  end

  class SillyIO < StringIO
    def clear
      truncate(0)
      rewind
    end
  end
end
