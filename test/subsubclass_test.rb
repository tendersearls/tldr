require "test_helper"

class SubSubclassTest < Minitest::Test
  def test_descendants
    result = TLDRunner.should_succeed("subsubclass.rb")

    assert_includes result.stdout, <<~MSG
      😁😁
    MSG
  end
end
