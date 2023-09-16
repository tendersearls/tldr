require "test_helper"

class TestTLDR < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::TLDR::VERSION
  end
end
