require "test_helper"

class ApiRunnerTest < Minitest::Test
  def test_run_method
    result = TLDRunner.run_command "bundle exec ruby test/driver/api_runner.rb"

    assert_includes result.stdout, <<~MSG
      Command: bundle exec tldr --seed 1 "test/fixture/c.rb"

      🏃 Running:

      C1
      😁C3
      😁C2
      😁
    MSG
  end
end
