# typed: strict

class MathSpec < TLDR
  extend T::Sig
  print_specs!

  sig { void }
  def test_it_is_math
    assert_equal 1 + 1, 2
  end
end
