require "test_helper"

class RakeTaskTest < Minitest::Test
  def test_running_rake
    result = TLDRunner.run_command "cd example/b && TLDR_OPTS=\"--seed 1\" bundle exec rake"

    puts result.stdout
    assert_includes result.stdout, <<~MSG
      neat!
      Command: bundle exec tldr --seed 1
      🌱 --seed 1

      🏃 Running:

      😁
    MSG
  end

  def test_running_custom_rake_task
    result = TLDRunner.run_command "cd example/b && TLDR_OPTS=\"--seed 1\" bundle exec rake safe_tests"

    assert_includes result.stdout, <<~MSG
      cool!
      Command: bundle exec tldr --seed 1 --helper "safe/helper.rb" --load-path "lib" --load-path "safe" "safe/big_test.rb"
      🌱 --seed 1

      🏃 Running:

      😁
    MSG
  end

  def test_running_custom_base_path
    result = TLDRunner.run_command "cd example/c && TLDR_OPTS=\"--seed 1\" bundle exec rake b_tests"

    assert_includes result.stdout, <<~MSG
      neat!
      Command: bundle exec tldr --seed 1 --base-path "../b"
      🌱 --seed 1

      🏃 Running:

      😁
    MSG
  end
end
