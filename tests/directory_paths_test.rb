require_relative "test_helper"

class DirectoryPathsTest < Minitest::Test
  def test_directories_work
    result = TLDRunner.should_succeed "folder"

    assert_includes result.stdout, "A1"
    assert_includes result.stdout, "B1"
  end
end
