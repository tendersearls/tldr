require_relative "tldr/version"
require_relative "tldr/planner"
require_relative "tldr/runner"
require_relative "tldr/reporter"
require_relative "tldr/assertions"

class TLDR
  class Error < StandardError; end
  Config = Struct.new :paths, keyword_init: true

  include Assertions

  def self.plan config = Config.new
    Planner.new.plan config
  end

  def self.run plan
    Runner.new.run plan
  end

  def self.report results
    Reporter.new.report results
  end
end
