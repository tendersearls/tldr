require "test_helper"

class SuiteSummaryTest < Minitest::Test
  def test_summary
    result = TLDRunner.should_fail "suite_summary.rb"

    assert_match(/Finished in \d+ms./, result.stdout)
    assert_includes result.stdout, <<~MSG.chomp
      2 test classes, 8 test methods, 2 failures, 2 errors, 2 skips
    MSG
  end

  def test_verbose_summary_too_slow
    result = TLDRunner.should_fail "suite_summary_too_slow.rb", "--verbose-cancelled-trace", ensure_time_bomb: true

    assert_match(/Finished in \d+ms./, result.stdout)
    assert_includes result.stdout, <<~MSG.chomp
      1 test class, 1 test method, 0 failures, 0 errors, 0 skips
    MSG
    assert_includes scrub_time(normalise_abs_paths(result.stderr)), <<~MSG.chomp
      🙅 1 test was cancelled in progress:
        XXXms - T2#test_2_1 [tests/fixture/suite_summary_too_slow.rb:8]
          Backtrace at the point of cancellation:
          /path/to/tldr/tests/fixture/suite_summary_too_slow.rb:9:in `sleep'
          /path/to/tldr/tests/fixture/suite_summary_too_slow.rb:9:in `test_2_1'
    MSG
  end

  private

  def scrub_time string
    string.gsub(/(\d+)ms/, "XXXms")
  end

  def normalise_abs_paths string
    parent_of_lib_folder = File.expand_path(File.join(__dir__, "../.."))
    string.gsub(parent_of_lib_folder, "/path/to")
  end
end
