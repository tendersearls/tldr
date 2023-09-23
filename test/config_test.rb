require "test_helper"

class ConfigTest < Minitest::Test
  def test_pre_defaults
    config = TLDR::Config.new

    assert_match(/--seed \d+/, config.to_full_args)
    assert_equal "\"lol.rb:4\"", config.to_single_path_args("lol.rb:4")
  end

  def test_defaults
    config = TLDR::Config.new

    assert_equal Concurrent.processor_count, config.workers
  end

  def test_default_workers_set_to_one_when_seed_is_set_explicitly
    config = TLDR::Config.new(seed: 1234)

    assert_equal 1, config.workers
  end

  def test_default_workers_configurable_when_seed_is_set_explicitly
    config = TLDR::Config.new
    config.seed = 1234
    config.workers = 42

    assert_equal 42, config.workers
  end

  def test_cli_conversion_with_custom_options
    config = TLDR::Config.new(
      seed: 42,
      no_helper: true,
      verbose: true,
      reporter: TLDR::Reporters::Base,
      helper: "test_helper.rb",
      load_paths: ["app", "lib"],
      workers: 3,
      names: ["/test_*/", "test_it"],
      fail_fast: true,
      prepend_tests: ["a.rb:3"],
      paths: ["a.rb:3", "b.rb"],
      exclude_paths: ["c.rb:4"],
      no_prepend: true,
      exclude_names: "test_b_1"
    )

    assert_equal <<~MSG.chomp, config.to_full_args
      --seed 42 --no-helper --verbose --reporter TLDR::Reporters::Base --helper "test_helper.rb" --load-path "app" --load-path "lib" --workers 3 --name "/test_*/" --name "test_it" --fail-fast --prepend "a.rb:3" --no-prepend --exclude-path "c.rb:4" --exclude-name "test_b_1" "a.rb:3" "b.rb"
    MSG

    assert_equal <<~MSG.chomp, config.to_single_path_args("lol.rb")
      --no-helper --verbose --reporter TLDR::Reporters::Base --helper "test_helper.rb" --load-path "app" --load-path "lib" --exclude-name "test_b_1" "lol.rb"
    MSG
  end

  def test_cli_conversion_cuts_off_prepended_pwd
    config = TLDR::Config.new(
      seed: 1,
      helper: "#{Dir.pwd}/test_helper.rb",
      load_paths: ["#{Dir.pwd}/app", "/lol/ok/lib"],
      prepend_tests: ["#{Dir.pwd}/foo.rb"],
      exclude_paths: ["#{Dir.pwd}/bar.rb"],
      paths: ["#{Dir.pwd}/baz.rb"]
    )

    assert_equal <<~MSG.chomp, config.to_full_args
      --seed 1 --helper "test_helper.rb" --load-path "app" --load-path "/lol/ok/lib" --workers 1 --prepend "foo.rb" --exclude-path "bar.rb" "baz.rb"
    MSG

    assert_equal <<~MSG.chomp, config.to_single_path_args("#{Dir.pwd}/baz.rb")
      --helper "test_helper.rb" --load-path "app" --load-path "/lol/ok/lib" "baz.rb"
    MSG
  end
end
