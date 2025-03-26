require_relative "test_helper"

class BacktraceFilterTest < Minitest::Test
  def setup
    @subject = TLDR::BacktraceFilter.new
  end

  def test_no_matches_just_dupes
    ar = ["foo", "bar", "baz"]

    assert_equal ar, @subject.filter(ar)
    refute_same ar, @subject.filter(ar)
  end

  def test_takes_leading_meaningful_frames_until_it_hits_internal_ones
    ar = [
      "/foo/bar/baz.rb:1:in `foo'",
      "/foo/bar/baz.rb:8:in `baz'",
      "#{TLDR::BacktraceFilter::BASE_PATH}/foo.rb:2:in `foo'",
      "/foo/bar/baz.rb:5:in `bar'"
    ]

    assert_equal ar[0..1], @subject.filter(ar)
  end

  def test_selects_meaningful_frames_if_starts_with_internal_sorbet_and_concurrent_ruby_ones
    ar = [
      "#{TLDR::BacktraceFilter::BASE_PATH}/foo.rb:1:in `foo'",
      "/foo/bar/baz.rb:1:in `foo'",
      "#{TLDR::BacktraceFilter::BASE_PATH}/foo.rb:2:in `foo'",
      "/foo/bar/baz.rb:5:in `bar'"
    ]

    assert_equal [ar[1], ar[3]], @subject.filter(ar)
  end
end
