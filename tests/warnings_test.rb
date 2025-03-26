require_relative "test_helper"

class WarningsTest < Minitest::Test
  def test_warnings
    result = TLDRunner.should_succeed "warnings.rb"

    assert_includes result.stderr, "warning: method redefined; discarding old test_warning"
  end

  def test_no_warnings
    result = TLDRunner.should_succeed "warnings.rb", "--no-warnings"

    refute_includes result.stderr, "warning: method redefined; discarding old test_warning"
  end
end
