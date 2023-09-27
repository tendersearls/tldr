require "concurrent-ruby"

require_relative "tldr/argv_parser"
require_relative "tldr/assertions"
require_relative "tldr/backtrace_filter"
require_relative "tldr/error"
require_relative "tldr/parallel_controls"
require_relative "tldr/parallelizer"
require_relative "tldr/path_util"
require_relative "tldr/planner"
require_relative "tldr/reporters"
require_relative "tldr/runner"
require_relative "tldr/skippable"
require_relative "tldr/sorbet_compatibility"
require_relative "tldr/strategizer"
require_relative "tldr/value"
require_relative "tldr/version"

class TLDR
  include Assertions
  include Skippable

  def setup
  end

  def teardown
  end

  module Run
    def self.cli argv
      config = ArgvParser.new.parse argv
      tests config
    end

    def self.tests config = Config.new
      Runner.new.run config, Planner.new.plan(config)
    end

    @@at_exit_registered = false
    def self.at_exit! config = Config.new
      # Ignore at_exit when running tldr CLI, since that will run any tests
      return if $PROGRAM_NAME.end_with? "tldr"
      # Ignore at_exit when we've already registered an at_exit hook
      return if @@at_exit_registered

      Kernel.at_exit do
        Run.tests config
      end

      @@at_exit_registered = true
    end
  end
end
