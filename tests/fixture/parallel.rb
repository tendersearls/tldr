class Parallel < TLDR
  # run manually with:
  #  $ time be tldr tests/fixture/parallel.rb
  # TODO - think of a clever way to assert runtime without just making the test suite slow in the precess
  (Concurrent.processor_count * 4).times do |i|
    define_method "test_#{i}" do
      sleep rand 0.2..0.8
      if i % 4 == 0
        assert false, "failing every fourth test and this is #{i}"
      end
    end
  end
end
