require "test_helper"

class CLITest < Minitest::Test
  def test_parsing_argv
    result = TLDR::ArgvParser.new.parse ["--seed", "1"]

    assert_equal TLDR::Config.new(seed: 1), result
  end
end
