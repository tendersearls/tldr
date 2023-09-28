require "tldr"

require "my_lib"

class BigTest < TLDR
  print_cool!

  def setup
    @subject = MyLib.new
  end

  def test_stuff
    assert_equal :stuff, @subject.return_stuff
  end
end
