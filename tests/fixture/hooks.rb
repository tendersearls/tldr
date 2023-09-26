class Hooks < TLDR
  def setup
    super
    print "\nA"
  end

  def test_1
    print "B"
  end

  def test_2
    print "B"
  end

  def teardown
    super
    print "C"
  end
end
