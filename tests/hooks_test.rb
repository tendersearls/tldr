require_relative "test_helper"

class HooksTest < Minitest::Test
  def test_hooks
    result = TLDRunner.should_succeed "hooks.rb", "--no-parallel -n test_1,test_2"

    assert_includes result.stdout, <<~MSG
      A(B)C.
      A(B)C.
    MSG
  end

  def test_uncalled_around_hook
    result = TLDRunner.should_fail "hooks.rb", "--no-parallel -n test_3"

    assert_includes result.stderr, "BadHook#around failed to yield or call the passed test block"
  end
end
