require "test_helper"

class ArgvParserTest < Minitest::Test
  def test_parsing_argv
    result = TLDR::ArgvParser.new.parse [
      "bar.rb",
      "--seed", "42",
      "-v",
      "foo.rb:3",
      "--reporter", "TLDR::Reporters::Base",
      "--no-helper",
      "--helper", "spec/spec_helper.rb",
      "-l", "lib",
      "-l", "vendor,spec",
      "--workers", "99",
      "--name", "foo",
      "--load-path", "app",
      "-n", "bar,baz"
    ]

    assert_equal ["bar.rb", "foo.rb:3"], result.paths
    assert_equal 42, result.seed
    assert result.no_helper
    assert result.verbose
    assert_equal TLDR::Reporters::Base, result.reporter
    assert_equal "spec/spec_helper.rb", result.helper
    assert_equal ["lib", "vendor", "spec", "app"], result.load_paths
    assert_equal 99, result.workers
    assert_equal ["foo", "bar", "baz"], result.names
  end

  def test_defaults
    result = TLDR::ArgvParser.new.parse []

    assert_equal Dir["test/**/*_test.rb", "test/**/test_*.rb"], result.paths
    assert_includes 0..10_000, result.seed
    refute result.no_helper
    refute result.verbose
    assert_equal TLDR::Reporters::Default, result.reporter
    assert_equal "test/helper.rb", result.helper
    assert_equal ["test"], result.load_paths
    assert_equal Concurrent::RubyThreadPoolExecutor::DEFAULT_MAX_POOL_SIZE, result.workers
    assert_equal [], result.names
  end
end
