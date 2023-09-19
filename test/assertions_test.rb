require "test_helper"
require "tldr/assertions/minitest"

class AssertionsTest < Minitest::Test
  class Asserty
    include TLDR::Assertions
  end

  def setup
    @subject = Asserty.new

    SuperDiff.configure do |config|
      config.color_enabled = false
    end
  end

  def test_assert
    @subject.assert true
    should_fail "Expected false to be truthy" do
      @subject.assert false
    end
    should_fail "Custom" do
      @subject.assert false, "Custom"
    end
  end

  def test_assert_empty
    @subject.assert_empty []
    should_fail "Expected [1] to be empty" do
      @subject.assert_empty [1]
    end
    should_fail "Neat\nExpected [2] to be empty" do
      @subject.assert_empty [2], "Neat"
    end
  end

  def test_assert_equal
    @subject.assert_equal 42, 42
    msg = <<~MSG.chomp
      Differing numbers.

      Expected: 41
        Actual: 42
    MSG
    should_fail msg do
      @subject.assert_equal 41, 42
    end
  end

  def test_assert_in_delta
    @subject.assert_in_delta 0.5, 0.51, 0.02
    should_fail "Expected |0.5 - 0.4| (0.09999999999999998) to be within 0.01" do
      @subject.assert_in_delta 0.5, 0.4, 0.01
    end
  end

  def test_assert_in_epsilon
    @subject.assert_in_epsilon 0.5, 0.51, 0.04
    should_fail "Expected |0.5 - 0.4| (0.09999999999999998) to be within 0.04000000000000001" do
      @subject.assert_in_epsilon 0.5, 0.4, 0.1
    end
  end

  def test_assert_include?
    @subject.assert_include? "foo", "food"
    should_fail "Expected \"drink\" to include \"foo\"" do
      @subject.assert_include? "foo", "drink"
    end
    should_fail(/Expected #<Object:0x.*> \(Object\) to respond to :include?/) do
      @subject.assert_include? "stuff", Object.new
    end
  end

  def test_assert_instance_of
    @subject.assert_instance_of Object, Object.new
    should_fail(/Expected #<Object:0x.*> to be an instance of String, not Object/) do
      @subject.assert_instance_of String, Object.new
    end
  end

  def test_assert_kind_of
    @subject.assert_kind_of Object, String.new("hi") # standard:disable Performance/UnfreezeString
    should_fail(/Expected #<Object:0x.*> to be a kind of String, not Object/) do
      @subject.assert_kind_of String, Object.new
    end
  end

  def test_assert_match?
    @subject.assert_match?(/foo/, "food")
    should_fail "Expected \"drink\" to match /foo/" do
      @subject.assert_match?(/foo/, "drink")
    end
    should_fail(/Expected #<Object:0x.*> \(Object\) to respond to :match?/) do
      @subject.assert_match? "stuff", Object.new
    end
  end

  def test_assert_nil
    @subject.assert_nil nil
    should_fail "Expected false to be nil" do
      @subject.assert_nil false
    end
    should_fail "Custom" do
      @subject.assert_nil 42, "Custom"
    end
  end

  def test_assert_operator
    @subject.assert_operator 1, :<, 2
    should_fail "Expected 1 to be > 2" do
      @subject.assert_operator 1, :>, 2
    end
  end

  def test_assert_respond_to
    @subject.assert_respond_to "foo", :length
    should_fail "Expected \"foo\" (String) to respond to :pizza" do
      @subject.assert_respond_to "foo", :pizza
    end
    should_fail "Custom.\nExpected \"foo\" (String) to respond to :pizza" do
      @subject.assert_respond_to "foo", :pizza, "Custom."
    end
  end

  def test_doesnt_call_message_procs_on_success
    @subject.assert_nil nil, proc { raise "Shouldn't be called" }
  end

  private

  def should_fail(message)
    e = assert_raises(TLDR::Assertions::Failure) {
      yield
    }

    if message.is_a?(String)
      assert_includes e.message, message
    elsif message.is_a?(Regexp)
      assert_match message, e.message
    else
      fail "Unknown message type: #{message.inspect}"
    end
  end
end
