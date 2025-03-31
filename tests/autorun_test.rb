require_relative "test_helper"

class AutorunTest < Minitest::Test
  def test_running_at_exit
    result = TLDRunner.run_command <<~CMD
      bundle exec ruby tests/fixture/autorun.rb --seed 42 --exclude-name "test_orange" --no-prepend
    CMD

    assert_includes result.stdout, <<~MSG.chomp
      Command: bundle exec tldr --seed 42 --exclude-name "test_orange" --no-prepend
      --seed 42

      Running:

      ..

      Finished
    MSG
  end
end
