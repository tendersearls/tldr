require "test_helper"

class RakeTaskTest < Minitest::Test
  def test_running_rake
    result = TLDRunner.run_command "cd example/b && TLDR_OPTS=\"--seed 1\" bundle exec rake"

    assert_includes result.stdout, <<~MSG
      neat!
      Command: bundle exec tldr --seed 1

      🏃 Running:

      😁
    MSG
  end
end
