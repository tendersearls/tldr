require "test_helper"

class ArgvParserTest < Minitest::Test
  def test_parsing_argv
    result = TLDR::ArgvParser.new.parse ["bar.rb", "--seed", "1", "foo.rb:3"]

    assert_equal TLDR::Config.new(seed: 1, paths: ["bar.rb", "foo.rb:3"]), result
  end
end
