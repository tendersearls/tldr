require_relative "test_helper"
require "fileutils"

class PrependTest < Minitest::Test
  def test_setting_explicitly_by_file_a
    result = TLDRunner.should_succeed ["folder/a.rb", "folder/b.rb"], "--prepend tests/fixture/folder/a.rb --seed 1"

    assert_these_appear_before_these result.stdout, ["A1", "A2", "A3"], ["B1", "B2", "B3"]
  end

  def test_setting_explicitly_by_line_number
    result = TLDRunner.should_succeed ["folder/a.rb", "folder/b.rb"], "--prepend tests/fixture/folder/a.rb:7 --seed 1"

    assert_these_appear_before_these result.stdout, ["A2"], ["A1", "A3", "B1", "B2", "B3"]
  end

  def test_setting_explicitly_by_multiple
    result = TLDRunner.should_succeed ["folder/a.rb", "folder/b.rb"], "--prepend tests/fixture/folder/a.rb:3:12 --prepend tests/fixture/folder/b.rb:8 --seed 1"

    assert_these_appear_before_these result.stdout, ["A1", "A3", "B2"], ["A2", "B1", "B3"]
  end

  def test_setting_explicitly_by_file_b
    result = TLDRunner.should_succeed ["folder/a.rb", "folder/b.rb"], "--prepend tests/fixture/folder/b.rb --seed 1"

    assert_these_appear_before_these result.stdout, ["B1", "B2", "B3"], ["A1", "A2", "A3"]
  end

  def test_modifying_file_changes_prepend_default
    FileUtils.touch("tests/fixture/folder/a.rb")
    result = TLDRunner.should_succeed ["folder/a.rb", "folder/b.rb"], "--seed 1"
    assert_these_appear_before_these result.stdout, ["A1", "A2", "A3"], ["B1", "B2", "B3"]

    FileUtils.touch("tests/fixture/folder/b.rb")
    result = TLDRunner.should_succeed ["folder/a.rb", "folder/b.rb"], "--seed 1"
    assert_these_appear_before_these result.stdout, ["B1", "B2", "B3"], ["A1", "A2", "A3"]
  end

  def test_no_prepend_does_not_prepend
    result = TLDRunner.should_succeed ["folder/a.rb", "folder/b.rb"], "--seed 1 --no-prepend"

    assert_strings_appear_in_this_order result.stdout, ["B3", "B2", "A2", "B1", "A1", "A3"]
  end

  def test_globs
    result = TLDRunner.should_succeed ["folder/*.rb", "c.rb"], "--prepend \"tests/fixture/folder/*.rb\" --seed 1"

    assert_these_appear_before_these result.stdout, ["A1", "A2", "A3", "B1", "B2", "B3"], ["C1", "C2", "C3"]
  end
end
