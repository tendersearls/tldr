require "tldr"

at_exit do
  TLDR::API.run(TLDR::Config.new(seed: 5, exclude_names: ["test_y"]))
end

class Z < TLDR
  def test_z
    puts "Z"
  end
end

class Y < TLDR
  def test_y
    puts "Y"
  end
end

class X < TLDR
  def test_x
    puts "X"
  end
end
