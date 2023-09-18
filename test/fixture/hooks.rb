class Hooks < TLDR
  def setup
    print "\nA"
  end

  def test_1
    print "B"
  end

  def test_2
    print "B"
  end

  def teardown
    print "C"
  end
end
