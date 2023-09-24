require "tldr"

TLDR::Run.at_exit! TLDR::Config.new(seed: 5, exclude_names: ["test_y"])

# First in wins
TLDR::Run.at_exit! TLDR::Config.new(seed: 5, exclude_names: ["test_z"])

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
