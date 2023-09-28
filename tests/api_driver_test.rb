require "test_helper"

class ApiDriverTest < Minitest::Test
  def test_run_method
    result = TLDRunner.run_command "bundle exec ruby tests/driver/api_driver.rb"

    assert_includes result.stdout, <<~MSG
      Command: bundle exec tldr --seed 1 "tests/fixture/c.rb"
      🌱 --seed 1

      🏃 Running:

      C1
      😁C3
      😁C2
      😁
    MSG
  end
end
