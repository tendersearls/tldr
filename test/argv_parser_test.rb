require "test_helper"

class ArgvParserTest < Minitest::Test
  def test_parsing_argv
    result = TLDR::ArgvParser.new.parse [
      "bar.rb",
      "--seed", "42",
      "-v",
      "foo.rb:3",
      "--reporter", "TLDR::Reporters::Base",
      "--skip-test-helper",
      "--helper", "spec/spec_helper.rb",
      "-l", "lib",
      "--workers", "99",
      "--load-path", "app"
    ]

    assert_equal ["bar.rb", "foo.rb:3"], result.paths
    assert_equal 42, result.seed
    assert result.skip_test_helper
    assert result.verbose
    assert_kind_of TLDR::Reporters::Base, result.reporter
    assert_equal "spec/spec_helper.rb", result.helper
    assert_equal ["lib", "app"], result.load_paths
    assert_equal 99, result.workers
  end

  def test_defaults
    result = TLDR::ArgvParser.new.parse []

    assert_equal Dir["test/**/*_test.rb", "test/**/test_*.rb"], result.paths
    assert_includes 0..10_000, result.seed
    refute result.skip_test_helper
    refute result.verbose
    assert_kind_of TLDR::Reporters::Default, result.reporter
    assert_equal "test/helper.rb", result.helper
    assert_equal ["test"], result.load_paths
    assert_equal Concurrent.processor_count, result.workers
  end
end
