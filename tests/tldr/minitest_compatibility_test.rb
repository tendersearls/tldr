require_relative "../test_helper"

class MinitestCompatibilityTest < AssertionTestCase
  class Compatty
    include TLDR::Assertions
    include TLDR::MinitestCompatibility
  end

  def setup
    super
    @subject = Compatty.new
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

  class CompatibleTldr < TLDR
    include TLDR::MinitestCompatibility
  end

  def test_tldr_doesnt_define_minitest_compatibility_methods_by_default
    refute_respond_to TLDR.new, :capture_io
    refute_respond_to TLDR.new, :mu_pp
    assert_respond_to CompatibleTldr.new, :capture_io
    assert_respond_to CompatibleTldr.new, :mu_pp
  end
end
