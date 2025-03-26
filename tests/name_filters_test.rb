require_relative "test_helper"

class NameFiltersTest < Minitest::Test
  def test_pattern
    result = TLDRunner.should_succeed "name_filters.rb", "--name /my_.*_case/"

    assert_includes result.stdout, "1️⃣"
    assert_includes result.stdout, "2️⃣"
    refute_includes result.stdout, "3️⃣"
  end

  def test_single
    result = TLDRunner.should_succeed "name_filters.rb", "--name test_my_second_case"

    refute_includes result.stdout, "1️⃣"
    assert_includes result.stdout, "2️⃣"
    refute_includes result.stdout, "3️⃣"
  end

  def test_with_class_name
    result = TLDRunner.should_succeed "name_filters.rb", "--name NameFilters#test_a_third_case"

    refute_includes result.stdout, "1️⃣"
    refute_includes result.stdout, "2️⃣"
    assert_includes result.stdout, "3️⃣"
  end

  def test_with_pattern_with_comma
    result = TLDRunner.should_succeed "name_filters.rb", "--name \"/test_my_[second]{1,6}_case/,test_my_first_case,/test_a_[third]{4,5}_case/\""

    assert_includes result.stdout, "1️⃣"
    assert_includes result.stdout, "2️⃣"
    assert_includes result.stdout, "3️⃣"
  end

  def test_with_class_name_and_regex
    result = TLDRunner.should_succeed "name_filters.rb", "--name \"/.*Filters#test_(a|my)_(second|third)_case/\""

    refute_includes result.stdout, "1️⃣"
    assert_includes result.stdout, "2️⃣"
    assert_includes result.stdout, "3️⃣"
  end

  def test_with_name_and_line_number_should_require_both_to_match
    result = TLDRunner.should_succeed "name_filters.rb:7:11", "--name \"/my_.*_case/\""

    refute_includes result.stdout, "1️⃣"
    assert_includes result.stdout, "2️⃣"
    refute_includes result.stdout, "3️⃣"
  end

  def test_multiple
    result = TLDRunner.should_succeed "name_filters.rb", "--name /second/,NameFilters#test_a_third_case -n test_my_first_case"

    assert_includes result.stdout, "1️⃣"
    assert_includes result.stdout, "2️⃣"
    assert_includes result.stdout, "3️⃣"
  end
end
