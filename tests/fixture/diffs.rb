class Diffs < TLDR
  def test_a_big_hash
    expected = {
      "a" => 1,
      :b => 2,
      :c => <<~MSG,
        Here
        is
        some
        long

        text!
      MSG
      :d => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    }

    actual = {
      "a" => 1,
      :b => 3,
      :c => <<~MSG,
        Here
        is
        some
        LONG

        text!
      MSG
      :d => [1, 2, 3, 4, 7, 6, 7, 8, 9, 10]
    }

    assert_equal expected, actual
  end
end
