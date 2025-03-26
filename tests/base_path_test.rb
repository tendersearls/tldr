require_relative "test_helper"

class BasePathTest < Minitest::Test
  def test_configuring_base_path
    result = TLDRunner.run_command("bundle exec tldr --seed 1 --no-prepend --base-path example/a")

    assert_empty result.stderr
    assert_includes result.stdout, <<~MSG
      Command: bundle exec tldr --seed 1 --no-prepend --base-path "example/a"
      🌱 --seed 1

      🏃 Running:

      😁😁
    MSG
  end
end
