require "test_helper"

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
      "/foo/bar/baz.rb:5:in `bar'",
      "ruby/gems/3.2.0/gems/sorbet-runtime-0.5.10983/lib/types/private/methods/_methods.rb:255"
    ]

    assert_equal ar[0..1], @subject.filter(ar)
  end

  def test_selects_meaningful_frames_if_starts_with_internal_sorbet_and_concurrent_ruby_ones
    ar = [
      "#{TLDR::BacktraceFilter::BASE_PATH}/foo.rb:1:in `foo'",
      "ruby/gems/3.2.0/gems/sorbet-runtime-0.5.10983/lib/types/private/methods/_methods.rb:255",
      "ruby/gems/3.2.0/gems/concurrent-ruby-1.2.2/lib/concurrent-ruby/concurrent/promises.rb:1583",
      "/foo/bar/baz.rb:1:in `foo'",
      "#{TLDR::BacktraceFilter::BASE_PATH}/foo.rb:2:in `foo'",
      "/foo/bar/baz.rb:5:in `bar'",
      "ruby/gems/3.2.0/gems/concurrent-ruby-1.2.2/lib/concurrent-ruby/concurrent/executor/ruby_thread_pool_executor.rb:352",
      "ruby\\gems\\3.2.0\\gems\\concurrent-ruby-1.2.2\\lib\\concurrent-ruby\\concurrent\\executor\\ruby_thread_pool_executor.rb:352",
      "ruby/gems/3.2.0/gems/sorbet-runtime-0.5.10983/lib/types/private/lol/_lol.rb:255",
      "ruby\\gems\\3.2.0\\gems\\sorbet-runtime-0.5.10983\\lib\\types\\private\\lol\\_lol.rb:255",
      "ruby/gems/3.2.0/gems/sorbet-runtime-0.5.10983/lib/types/private/methods/_methods.rb:255"
    ]

    assert_equal [ar[3], ar[5]], @subject.filter(ar)
  end
end
