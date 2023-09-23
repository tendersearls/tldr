class FailFast < TLDR
  def test_fail
    sleep 0.1
    assert false
  end

  def test_pass_already_run
    sleep 0.05
  end

  def test_pass_wont_finish
    sleep 0.2
  end

  def test_pass_wont_even_run
  end
end
