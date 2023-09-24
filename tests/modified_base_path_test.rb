require "test_helper"

class ModifiedBasePathTest < Minitest::Test
  def test_configuring_base_path
    result = TLDRunner.run_command "bundle exec tldr --seed 1 --no-prepend --base-path example/a"

    assert_empty result.stderr
    assert_includes result.stdout, <<~MSG
      Command: bundle exec tldr --seed 1 --no-prepend --base-path "example/a"

      🏃 Running:

      😁😁
    MSG
  end
end
