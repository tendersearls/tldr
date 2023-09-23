require "test_helper"

class ExcludePathTest < Minitest::Test
  def test_a_simple_exclude_path
    result = TLDRunner.should_succeed "folder", "--exclude-path test/fixture/folder/b.rb:3"

    assert_includes_all result.stdout, ["A1", "A2", "A3", "B2", "B3"]
    refute_includes result.stdout, "B1"
  end

  def test_a_glob
    result = TLDRunner.should_succeed "**", "--exclude-path \"test/fixture/**\""

    assert_includes result.stdout, "0 test methods"
  end

  def test_errors_on_glob_plus_line_number
    result = TLDRunner.should_fail "folder", "--exclude-path \"test/fixture/folder/*.rb:4\""

    assert_includes result.stderr, "Can't combine globs and line numbers in: test/fixture/folder/*.rb:4 (TLDR::Error)"
  end
end
