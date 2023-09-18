require_relative "tldr/version"
require_relative "tldr/value"
require_relative "tldr/reporters"
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
    config = ArgvParser.new.parse(argv)
    report(config, run(config, plan(config)))
  end

  def self.plan config
    Planner.new.plan config
  end

  def self.run config, plan
    Runner.new.run config, plan
  end

  def self.report config, results
    Reporter.new.report config, results
  end
end
