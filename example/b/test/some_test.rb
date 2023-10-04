require "tldr"
TLDR::Run.at_exit!(TLDR::Config.new(fail_fast: true))

require "helper"

class SomeTest < TLDR
  print_neat!

  def test_truth
    assert true
  end
end
