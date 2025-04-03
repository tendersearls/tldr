require_relative "test_helper"

class CustomReporterTest < Minitest::Test
  def test_success
    result = TLDRunner.should_succeed "success.rb", <<~OPTIONS
      --helper tests/fixture/custom_reporter_helper.rb --reporter "SuitReporter"
    OPTIONS

    assert_empty result.stderr
    assert_equal "♠︎", result.stdout
  end

  def test_suite_summary
    result = TLDRunner.should_fail "suite_summary.rb", <<~OPTIONS
      --helper tests/fixture/custom_reporter_helper.rb --reporter "SuitReporter" --seed 22
    OPTIONS

    assert_empty result.stderr
    assert_equal "♣︎♦︎♥︎♦︎♠︎♥︎♠︎♣︎", result.stdout
  end

  def test_unknown_reporter
    result = TLDRunner.should_fail "suite_summary.rb", <<~OPTIONS
      --helper tests/fixture/custom_reporter_helper.rb --reporter "PantsReporter"
    OPTIONS

    assert_includes result.stderr, <<~MSG.chomp
      Unknown reporter 'PantsReporter' (are you sure it was loaded by your test or helper?)
    MSG
    assert_empty result.stdout
  end

  def test_no_hooks_defined
    result = TLDRunner.should_succeed "success.rb", <<~OPTIONS
      --helper tests/fixture/custom_reporter_helper.rb --reporter "HooklessReporter"
    OPTIONS

    assert_empty result.stderr
    assert_empty result.stdout
  end

  def test_invalid_reporter
    result = TLDRunner.should_fail "suite_summary.rb", <<~OPTIONS
      --helper tests/fixture/custom_reporter_helper.rb --reporter "InvalidReporter"
    OPTIONS

    assert_includes result.stderr, <<~MSG.chomp
      Reporter 'InvalidReporter' expected to be a class, but was a Module
    MSG
    assert_empty result.stdout
  end
end
