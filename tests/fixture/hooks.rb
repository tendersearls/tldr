class Hooks < TLDR
  def setup
    super
    print "\nA"
  end

  def around &test
    print "("
    test.call
    print ")"
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

class BadHook < TLDR
  def around &test
    print "("
    # wups, didn't call test.call!
    print ")"
  end

  def test_3
    print "🎯"
  end
end
