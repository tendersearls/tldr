require_relative "test_helper"

class DotfileTest < Minitest::Test
  def test_a_dotfile
    result = TLDRunner.run_command("BUNDLE_GEMFILE=\"example/c/Gemfile\" bundle exec tldr --seed 1 --no-prepend --base-path example/c")

    assert_empty result.stderr
    assert_includes result.stdout, <<~MSG
      👓
      Command: bundle exec tldr --seed 1 --helper "spec/spec_helper.rb" --no-prepend --base-path "example/c" "spec/math_spec.rb"
      --seed 1

      Running:

      .
    MSG
  end

  def test_no_config_path_doesnt_load_those_settings
    result = TLDRunner.run_command("bundle exec tldr --seed 1 --no-prepend --base-path example/c --no-config")

    assert_empty result.stderr
    assert_includes result.stdout, <<~MSG
      Command: bundle exec tldr --seed 1 --no-prepend --base-path "example/c" --no-config
    MSG
    assert_includes result.stdout, "0 test methods"
  end

  def test_a_lot_of_values_in_a_dotfile
    result = TLDRunner.run_command("bundle exec tldr --base-path example/d")

    refute result.success?
    assert_includes result.stdout, <<~MSG
      Command: bundle exec tldr --fail-fast --seed 42 --parallel --name "/test_*/" --name "test_it" --exclude-name "test_b_1" --exclude-path "c.rb:4" --helper "test_helper.rb" --prepend "a.rb:3" --load-path "app" --load-path "lib" --base-path "example/d" --verbose "b.rb"
    MSG
    assert_includes result.stderr, <<~MSG
      1) BTest#test_b_2 [b.rb:7] errored:
      wups

        Re-run this test:
          bundle exec tldr --base-path "example/d" "b.rb:6"
    MSG
  end

  def test_overriding_a_lot_of_values_in_a_dotfile
    result = TLDRunner.run_command("bundle exec tldr --base-path example/d --seed 5 --load-path foo --no-parallel --name test_stuff --prepend nope --exclude-path nada --exclude-name test_b_2")

    assert result.success?
    assert_includes result.stdout, <<~MSG
      Command: bundle exec tldr --fail-fast --seed 5 --name "test_stuff" --exclude-name "test_b_2" --exclude-path "nada" --helper "test_helper.rb" --prepend "nope" --load-path "foo" --base-path "example/d" --verbose "b.rb"
    MSG
  end

  def test_a_custom_dotfile_path
    result = TLDRunner.run_command("BUNDLE_GEMFILE=\"example/a/Gemfile\" bundle exec tldr --seed 1 --base-path example/a --config config/TldrFile")

    assert_empty result.stderr
    assert_includes result.stdout, <<~MSG
      Command: bundle exec tldr --seed 1 --base-path "example/a" --config config/TldrFile "test/test_subtract.rb"
    MSG
  end
end
