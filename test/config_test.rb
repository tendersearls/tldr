require "test_helper"

class ConfigTest < Minitest::Test
  def test_pre_defaults
    config = TLDR::Config.new

    assert_equal "", config.to_full_args
    assert_equal "\"lol.rb:4\"", config.to_single_path_args("lol.rb:4")
  end

  def test_defaults
    config = TLDR::Config.new

    config.set_defaults!

    assert_equal Concurrent.processor_count, config.workers
  end

  def test_default_workers_set_to_one_when_seed_is_set_explicitly
    config = TLDR::Config.new
    config.seed = 1234

    config.set_defaults!

    assert_equal 1, config.workers
  end

  def test_default_workers_configurable_when_seed_is_set_explicitly
    config = TLDR::Config.new
    config.seed = 1234
    config.workers = 42

    config.set_defaults!

    assert_equal 42, config.workers
  end

  def test_cli_conversion_with_custom_options
    config = TLDR::Config.new(
      seed: 42,
      skip_test_helper: true,
      verbose: true,
      reporter: TLDR::Reporters::Base,
      helper: "test_helper.rb",
      load_paths: ["app", "lib"],
      workers: 3,
      names: ["/test_*/", "test_it"],
      fail_fast: true,
      prepend_tests: ["a.rb:3"],
      paths: ["a.rb:3", "b.rb"],
      no_prepend: true
    )

    assert_equal <<~MSG.chomp, config.to_full_args
      --seed 42 --skip-test-helper --verbose --reporter TLDR::Reporters::Base --helper "test_helper.rb" --load-path "app" --load-path "lib" --workers 3 --name "/test_*/" --name "test_it" --fail-fast --prepend "a.rb:3" --no-prepend "a.rb:3" "b.rb"
    MSG

    assert_equal <<~MSG.chomp, config.to_single_path_args("lol.rb")
      --skip-test-helper --verbose --reporter TLDR::Reporters::Base --helper "test_helper.rb" --load-path "app" --load-path "lib" "lol.rb"
    MSG
  end
end
