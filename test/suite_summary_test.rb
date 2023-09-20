require "test_helper"

class SuiteSummaryTest < Minitest::Test
  def test_summary
    result = TLDRunner.should_fail "suite_summary.rb"

    assert_match(/Finished in \d+ms./, result.stdout)
    assert_includes result.stdout, <<~MSG.chomp
      1 test class, 8 test methods, 2 failures, 2 errors, 2 skips
    MSG
  end
end
