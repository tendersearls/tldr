require "test_helper"

class DotfileTest < Minitest::Test
  def test_a_dotfile
    result = TLDRunner.run_command "bundle exec tldr --seed 1 --no-prepend --base-path example/c"

    assert_empty result.stderr
    assert_includes result.stdout, <<~MSG
      👓
      Command: bundle exec tldr --seed 1 --helper "spec/spec_helper.rb" --no-prepend --base-path "example/c" "spec/math_spec.rb"

      🏃 Running:

      😁
    MSG
  end

  def test_no_dotfile_doesnt_load_those_settings
    result = TLDRunner.run_command "bundle exec tldr --seed 1 --no-prepend --no-dotfile --base-path example/c"

    assert_empty result.stderr
    assert_includes result.stdout, <<~MSG
      Command: bundle exec tldr --seed 1 --no-prepend --base-path "example/c" --no-dotfile
    MSG
    assert_includes result.stdout, "0 test methods"
  end

  def test_a_lot_of_values_in_a_dotfile
    result = TLDRunner.run_command "bundle exec tldr --base-path example/d"

    assert_empty result.stderr
    assert_includes result.stdout, <<~MSG
      Command: bundle exec tldr --seed 42 --verbose --helper "test_helper.rb" --load-path "app" --load-path "lib" --parallel --name "/test_*/" --name "test_it" --fail-fast --prepend "a.rb:3" --exclude-path "c.rb:4" --exclude-name "test_b_1" --base-path "example/d"
    MSG
  end

  def test_overriding_a_lot_of_values_in_a_dotfile
    result = TLDRunner.run_command "bundle exec tldr --base-path example/d --seed 5 --load-path foo --no-parallel --name test_stuff --prepend nope --exclude-path nada --exclude-name test_b_2"

    assert_empty result.stderr
    assert_includes result.stdout, <<~MSG
      Command: bundle exec tldr --seed 5 --verbose --helper "test_helper.rb" --load-path "foo" --name "test_stuff" --fail-fast --prepend "nope" --exclude-path "nada" --exclude-name "test_b_2" --base-path "example/d"
    MSG
  end
end
