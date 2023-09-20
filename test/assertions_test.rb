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

  def test_assert_output
    @subject.assert_output "foo\n", "bar\n" do
      puts "foo"
      warn "bar"
    end
    @subject.assert_output(/fo/, /ar/) do
      puts "foo"
      warn "bar"
    end
    should_fail(/Expected: "qux\\n"/) do
      @subject.assert_output "baz\n", "qux\n" do
        puts "foo"
        warn "bar"
      end
    end
    should_fail(/Expected: "baz\\n"/) do
      @subject.assert_output "baz\n", "bar\n" do
        puts "foo"
        warn "bar"
      end
    end
  end

  def test_assert_path_exists
    @subject.assert_path_exists "./tldr.gemspec"
    should_fail "Expected \"./lolnope\" to exist" do
      @subject.assert_path_exists "./lolnope"
    end
  end

  def test_assert_pattern
    @subject.assert_pattern { [1, 2, 3] => [Integer, Integer, Integer] }
    should_fail "Expected pattern match: [1, \"two\", 3]: Integer === \"two\" does not return true" do
      @subject.assert_pattern { [1, "two", 3] => [Integer, Integer, Integer] }
    end
    should_fail "Custom\nExpected pattern match: [1, \"two\", 3]: Integer === \"two\" does not return true" do
      @subject.assert_pattern("Custom") { [1, "two", 3] => [Integer, Integer, Integer] }
    end
  end

  def test_assert_predicate
    @subject.assert_predicate 1, :odd?
    should_fail "Expected 2 to be odd?" do
      @subject.assert_predicate 2, :odd?
    end
  end

  def test_assert_raises
    @subject.assert_raises(ArgumentError) { raise ArgumentError }
    @subject.assert_raises(IOError, ArgumentError) { raise ArgumentError }
    nested_e = assert_raises TLDR::Assertions::Failure do
      @subject.assert_raises {
        @subject.assert_empty [1]
      }
    end
    assert_equal "Expected [1] to be empty", nested_e.message
    should_fail "StandardError expected but nothing was raised." do
      @subject.assert_raises {}
    end
    msg = <<~MSG
      [TypeError] exception expected, not
      Class: <IOError>
      Message: <"lol">
      ---Backtrace---
    MSG
    should_fail msg do
      @subject.assert_raises(TypeError) { raise IOError, "lol" }
    end
    assert_raises(TLDR::SkipTest) {
      @subject.assert_raises {
        raise TLDR::SkipTest
      }
    }
    msg2 = <<~MSG
      Should've been different
      [IOError, ArgumentError] exception expected, not
      Class: <TypeError>
      Message: <"TypeError">
      ---Backtrace---
    MSG
    should_fail msg2 do
      @subject.assert_raises(IOError, ArgumentError, "Should've been different") { raise TypeError }
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
