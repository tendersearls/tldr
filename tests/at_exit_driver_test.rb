require_relative "test_helper"

class AtExitDriverTest < Minitest::Test
  def test_running_at_exit
    result = TLDRunner.run_command("bundle exec ruby tests/driver/at_exit_driver.rb")

    assert_includes result.stdout, <<~MSG
      Command: bundle exec tldr --seed 5 --exclude-name "test_y"
      --seed 5

      Running:

      X
      .Z
      .
    MSG
  end

  def test_running_cli_when_at_exit_is_also_there_only_runs_once
    result = TLDRunner.run_command("bundle exec tldr tests/driver/at_exit_driver.rb --exclude-name test_x --seed 1")

    # tldr command wins
    assert_equal result.stdout.scan("Command: bundle exec tldr").size, 1
    assert_includes result.stdout, <<~MSG
      Running:

      Y
      .Z
      .
    MSG
  end
end
