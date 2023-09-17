require_relative "tldr/version"
require_relative "tldr/argv_parser"
require_relative "tldr/planner"
require_relative "tldr/runner"
require_relative "tldr/reporter"
require_relative "tldr/assertions"
require_relative "tldr/skippable"

class TLDR
  class Error < StandardError; end

  include Assertions
  include Skippable

  def self.cli argv
    report(run(plan(ArgvParser.new.parse(argv))))
  end

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
