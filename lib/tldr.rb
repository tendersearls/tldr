require_relative "tldr/version"
require_relative "tldr/error"
require_relative "tldr/value"
require_relative "tldr/reporters"
require_relative "tldr/argv_parser"
require_relative "tldr/planner"
require_relative "tldr/runner"
require_relative "tldr/assertions"
require_relative "tldr/skippable"

class TLDR
  include Assertions
  include Skippable

  def self.cli argv
    config = ArgvParser.new.parse(argv)
    run(config)
  end

  def self.run config
    config.set_defaults!
    Runner.new.run(config, Planner.new.plan(config))
  end
end
