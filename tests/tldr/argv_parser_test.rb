require_relative "../test_helper"

class ArgvParserTest < Minitest::Test
  def test_parsing_argv
    result = TLDR::ArgvParser.new.parse([
      "bar.rb",
      "--seed", "42",
      "--timeout", "1.4",
      "-v",
      "--print-interrupted-test-backtraces",
      "foo.rb:3",
      "--reporter", "TLDR::Reporters::Base",
      "--no-helper",
      "--helper", "spec/spec_helper.rb",
      "-l", "lib",
      "-l", "vendor,spec",
      "--no-parallel",
      "--name", "foo",
      "--load-path", "app",
      "-n", "bar,baz",
      "--yes-i-know"
    ])

    assert_equal ["bar.rb", "foo.rb:3"], result.paths
    assert_equal 42, result.seed
    assert_equal result.timeout, 1.4
    assert result.no_helper
    assert result.verbose
    assert_equal TLDR::Reporters::Base, result.reporter
    assert_equal ["spec/spec_helper.rb"], result.helper_paths
    assert_equal ["lib", "vendor", "spec", "app"], result.load_paths
    refute result.parallel
    assert_equal ["foo", "bar", "baz"], result.names
    assert result.yes_i_know
  end

  def test_defaults
    result = TLDR::ArgvParser.new.parse([])

    assert_equal Dir["test/**/*_test.rb", "test/**/test_*.rb"], result.paths
    assert_includes 0..10_000, result.seed
    assert_equal result.timeout, 1.8
    refute result.no_helper
    refute result.verbose
    refute result.print_interrupted_test_backtraces
    assert_equal TLDR::Reporters::Default, result.reporter
    assert_equal ["test/helper.rb"], result.helper_paths
    assert_equal ["lib", "test"], result.load_paths
    assert result.parallel
    assert_equal [], result.names
    refute result.yes_i_know
  end

  def test_timeout_arg_specifically
    assert_equal TLDR::Config::DEFAULT_TIMEOUT, TLDR::ArgvParser.new.parse([]).timeout
    assert_equal 1.6, TLDR::ArgvParser.new.parse(["--timeout", "1.6"]).timeout
    assert_equal(-1, TLDR::ArgvParser.new.parse(["--no-timeout"]).timeout)
    # last-in wins:
    assert_equal 1.4, TLDR::ArgvParser.new.parse(["--no-timeout", "--timeout", "1.4"]).timeout
    assert_equal(-1, TLDR::ArgvParser.new.parse(["--timeout", "1.4", "--no-timeout"]).timeout)
    assert_equal(TLDR::Config::DEFAULT_TIMEOUT, TLDR::ArgvParser.new.parse(["--no-timeout", "--timeout", "--seed", "42"]).timeout)
  end
end
