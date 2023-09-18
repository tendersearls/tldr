require "concurrent"

class Parallel < TLDR
  # run manually with:
  #  $ time be tldr test/fixture/parallel.rb
  # TODO - think of a clever way to assert runtime without just making the test suite slow in the precess
  Concurrent.processor_count.times do |i|
    define_method "test_#{i}" do
      sleep 0.1 * i
      if i % 4 == 0
        assert false, "failing every fourth test and this is #{i}"
      end
    end
  end
end
