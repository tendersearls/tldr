require "test_helper"

class MinitestCompatibilityTest < AssertionTestCase
  class Compatty
    include TLDR::Assertions
    include TLDR::Assertions::MinitestCompatibility
  end

  def setup
    super
    @subject = Compatty.new
  end

  def test_assert_includes
    @subject.assert_includes "food", "foo"
    should_fail "Expected \"drink\" to include \"foo\"" do
      @subject.assert_includes "drink", "foo"
    end
    should_fail(/Expected #<Object:0x.*> \(Object\) to respond to :include?/) do
      @subject.assert_includes Object.new, "stuff"
    end
  end

  def test_refute_includes
    @subject.refute_includes "foo", "drink"
    should_fail "Expected \"food\" to not include \"foo\"" do
      @subject.refute_includes "food", "foo"
    end
    should_fail(/Expected #<Object:0x.*> \(Object\) to respond to :include?/) do
      @subject.refute_includes Object.new, "stuff"
    end
  end

  def test_assert_send
    assert_output "", /DEPRECATED: assert_send. From .*minitest_compatibility_test.rb:.*/ do
      @subject.assert_send [1, :<, 2]
    end
    assert_output "", /DEPRECATED: assert_send. From .*minitest_compatibility_test.rb:.*/ do
      should_fail "Expected 1.>(*[2]) to return true" do
        @subject.assert_send [1, :>, 2]
      end
    end
  end

  def test_capture_io
    out, err = @subject.capture_io do
      puts "out"
      warn "err"
    end

    assert_equal "out\n", out
    assert_equal "err\n", err
  end

  def test_mu_pp
    assert_equal "\"foo\"", @subject.mu_pp("foo")
    assert_includes @subject.mu_pp("Hello, 世界!".encode("UTF-32LE")), <<~MSG.chomp
      # encoding: UTF-32LE
      #    valid: true
      "Hello,
    MSG
  end
end
