require "test_helper"

class ExcludePathTest < Minitest::Test
  def test_a_simple_exclude_name
    result = TLDRunner.should_succeed "folder", "--exclude-name test_b_1"

    assert_includes_all result.stdout, ["A1", "A2", "A3", "B2", "B3"]
    refute_includes result.stdout, "B1"
  end

  def test_three_names
    result = TLDRunner.should_succeed "folder", "--exclude-name test_b_1,test_a_2 --exclude-name test_b_3"

    assert_includes_all result.stdout, ["A1", "A3", "B2"]
    assert_includes_none result.stdout, ["B1", "A2", "B3"]
  end

  def test_a_pattern_with_commas
    result = TLDRunner.should_succeed "folder", "--exclude-name \"/test_(a|b)_[23]{1,2}/\""

    assert_includes_all result.stdout, ["A1", "B1"]
    assert_includes_none result.stdout, ["A2", "B2", "A3", "B3"]
  end
end
