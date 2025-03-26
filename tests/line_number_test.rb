require_relative "test_helper"

class LineNumberTest < Minitest::Test
  def test_line_number_exact_hit
    result = TLDRunner.should_succeed "line_number.rb:2"

    assert_includes result.stdout, "😁"
    refute_includes result.stdout, "🫥"
    refute_includes result.stderr, "😡"
  end

  def test_line_number_intra_method
    result = TLDRunner.should_succeed "line_number.rb:3"

    assert_includes result.stdout, "😁"
    refute_includes result.stdout, "🫥"
    refute_includes result.stderr, "😡"
  end

  def test_line_number_end_of_method
    result = TLDRunner.should_succeed "line_number.rb:4"

    assert_includes result.stdout, "😁"
    refute_includes result.stdout, "🫥"
    refute_includes result.stderr, "😡"
  end

  def test_line_number_two_methods
    result = TLDRunner.should_fail "line_number.rb:3:11"

    assert_includes result.stdout, "😁"
    assert_includes result.stdout, "😡"
    refute_includes result.stdout, "🫥"
  end

  def test_line_number_three_methods
    result = TLDRunner.should_fail "line_number.rb:3:8:11"

    assert_includes result.stdout, "😁"
    assert_includes result.stdout, "🫥"
    assert_includes result.stdout, "😡"
  end

  def test_line_number_three_methods_over_two_patterns
    result = TLDRunner.should_fail ["line_number.rb:3:11", "line_number.rb:8"]

    assert_includes result.stdout, "😁"
    assert_includes result.stdout, "🫥"
    assert_includes result.stdout, "😡"
  end

  def test_line_number_nonsense
    result = TLDRunner.should_succeed "line_number.rb:999:42:5"

    refute_includes result.stdout, "😁"
    refute_includes result.stdout, "🫥"
    refute_includes result.stderr, "😡"
  end
end
