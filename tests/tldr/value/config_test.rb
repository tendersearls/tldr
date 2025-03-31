require_relative "../../test_helper"

class ConfigTest < Minitest::Test
  def test_pre_defaults
    config = TLDR::Config.new

    assert_equal "", config.to_full_args
    assert_equal "\"lol.rb:4\"", config.to_single_path_args("lol.rb:4")
  end

  def test_cli_defaults
    config = TLDR::Config.new(cli_defaults: true)

    # Won't work unless we change dir to example/a and it'll create pollution
    # assert_equal ["test/add_test.rb", "test/test_subtract.rb"], config.paths
    assert_equal ["test/helper.rb"], config.helper_paths
    assert_equal ["lib", "test"], config.load_paths
    assert_equal [TLDR::MOST_RECENTLY_MODIFIED_TAG], config.prepend_paths
    assert config.warnings
  end

  def test_non_cli_defaults
    config = TLDR::Config.new(cli_defaults: false)

    assert_equal "", config.to_full_args
    assert_equal [], config.paths
    assert_equal [], config.helper_paths
    assert_equal [], config.load_paths
    assert_equal [], config.prepend_paths
  end

  def test_default_no_parallel_when_seed_is_set_explicitly
    config = TLDR::Config.new(seed: 1234)

    refute config.parallel
  end

  def test_parallel_configurable_when_seed_is_set_explicitly
    config = TLDR::Config.new
    config.seed = 1234
    config.parallel = true

    assert config.parallel
  end

  def test_cli_conversion_with_custom_options
    config = TLDR::Config.new(
      seed: 42,
      verbose: true,
      print_interrupted_test_backtraces: true,
      reporter: TLDR::Reporters::Base,
      helper_paths: ["test_helper.rb"],
      load_paths: ["app", "lib"],
      parallel: true,
      names: ["/test_*/", "test_it"],
      fail_fast: true,
      prepend_paths: ["a.rb:3"],
      paths: ["a.rb:3", "b.rb"],
      exclude_paths: ["c.rb:4"],
      exclude_names: ["test_b_1"],
      warnings: false,
      yes_i_know: true,
      i_am_being_watched: true
    )

    assert_equal <<~MSG.chomp, config.to_full_args
      --fail-fast --parallel --seed 42 --name "/test_*/" --name "test_it" --exclude-name "test_b_1" --exclude-path "c.rb:4" --helper "test_helper.rb" --prepend "a.rb:3" --load-path "app" --load-path "lib" --reporter TLDR::Reporters::Base --no-warnings --verbose --yes-i-know --print-interrupted-test-backtraces "a.rb:3" "b.rb"
    MSG

    assert_equal <<~MSG.chomp, config.to_single_path_args("lol.rb")
      --exclude-name "test_b_1" --helper "test_helper.rb" --load-path "app" --load-path "lib" --reporter TLDR::Reporters::Base --no-warnings --verbose --yes-i-know --print-interrupted-test-backtraces "lol.rb"
    MSG

    assert_equal <<~MSG.chomp, config.to_full_args(ensure_args: ["--i-am-being-watched"])
      --fail-fast --parallel --seed 42 --name "/test_*/" --name "test_it" --exclude-name "test_b_1" --exclude-path "c.rb:4" --helper "test_helper.rb" --prepend "a.rb:3" --load-path "app" --load-path "lib" --reporter TLDR::Reporters::Base --no-warnings --verbose --yes-i-know --print-interrupted-test-backtraces "a.rb:3" "b.rb" --i-am-being-watched
    MSG
  end

  def test_cli_conversion_omits_prepend_with_no_prepend
    config = TLDR::Config.new(
      seed: 1,
      no_prepend: true,
      prepend_paths: ["a.rb:3"]
    )

    assert_equal <<~MSG.chomp, config.to_full_args
      --seed 1 --no-prepend
    MSG
  end

  def test_parallel_logic
    assert_includes TLDR::Config.new(parallel: true, seed: 1).to_full_args, "--parallel"
    refute_includes TLDR::Config.new(parallel: true).to_full_args, "--parallel"
    assert_includes TLDR::Config.new(parallel: false).to_full_args, "--no-parallel"
    refute_includes TLDR::Config.new(parallel: false, seed: 1).to_full_args, "--parallel"
  end

  def test_timeout_arg_printout
    assert_equal "--timeout", TLDR::Config.new(timeout: 1.8).to_full_args
    assert_equal "--timeout 1.7", TLDR::Config.new(timeout: 1.7).to_full_args
  end

  def test_config_path_arg_printout
    assert_equal "--config loljk.yml", TLDR::Config.new(config_path: "loljk.yml").to_full_args
    assert_equal "", TLDR::Config.new(config_path: nil).to_full_args
    assert_equal "--no-config", TLDR::Config.new(config_path: nil, cli_defaults: true).to_full_args
    assert_equal "", TLDR::Config.new(config_path: TLDR::Config::DEFAULT_YAML_PATH, cli_defaults: true).to_full_args
  end

  def test_cli_conversion_omits_helper_with_no_helper
    config = TLDR::Config.new(
      seed: 1,
      no_helper: true,
      helper_paths: ["some/silly/helper.rb"]
    )

    assert_equal <<~MSG.chomp, config.to_full_args
      --seed 1 --no-helper
    MSG
  end

  def test_cli_conversion_cuts_off_prepended_pwd
    config = TLDR::Config.new(
      seed: 1,
      helper_paths: ["#{Dir.pwd}/test_helper.rb"],
      load_paths: ["#{Dir.pwd}/app", "/lol/ok/lib"],
      prepend_paths: ["#{Dir.pwd}/foo.rb"],
      exclude_paths: ["#{Dir.pwd}/bar.rb"],
      paths: ["#{Dir.pwd}/baz.rb"]
    )

    assert_equal <<~MSG.chomp, config.to_full_args
      --seed 1 --exclude-path "bar.rb" --helper "test_helper.rb" --prepend "foo.rb" --load-path "app" --load-path "/lol/ok/lib" "baz.rb"
    MSG

    assert_equal <<~MSG.chomp, config.to_single_path_args("#{Dir.pwd}/baz.rb")
      --helper "test_helper.rb" --load-path "app" --load-path "/lol/ok/lib" "baz.rb"
    MSG
  end

  def test_cli_summary_ignores_prepend_when_it_matches_paths
    config = TLDR::Config.new(
      seed: 1,
      prepend_paths: ["#{Dir.pwd}/foo.rb", "bar.rb"],
      paths: ["#{Dir.pwd}/bar.rb", "foo.rb"]
    )

    assert_equal <<~MSG.chomp, config.to_full_args
      --seed 1 "bar.rb" "foo.rb"
    MSG
  end

  def test_cli_summary_ignores_no_parallel_when_seed_is_set
    config = TLDR::Config.new(
      seed: 1,
      paths: ["foo.rb"]
    )

    assert_equal <<~MSG.chomp, config.to_full_args
      --seed 1 "foo.rb"
    MSG
  end

  def test_merging_configs_basic
    config = TLDR::Config.new(emoji: true, prepend_paths: ["a.rb:1"], paths: ["a.rb"])
    other = TLDR::Config.new(emoji: false, seed: 1, prepend_paths: ["a.rb:2"], config_intended_for_merge_only: true)

    result = config.merge(other)

    refute_same result, config
    refute result.config_intended_for_merge_only
    # Seed logic still works, it was just resolved by the otherconfig
    assert result.seed_set_intentionally
    assert_equal 1, result.seed
    refute result.parallel
    # Basic merging happens
    assert_equal ["a.rb"], result.paths
    assert_equal ["a.rb:2"], result.prepend_paths
    refute result.emoji
  end
end
