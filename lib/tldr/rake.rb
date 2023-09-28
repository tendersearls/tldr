require "rake"
require "shellwords"

require "tldr"

class TLDR
  class Task
    include Rake::DSL

    def initialize(name: "tldr", config: Config.new)
      define name, config
    end

    private

    def define name, task_config
      desc "Run #{name} tests (use TLDR_OPTS or .tldr.yml to configure)"
      task name do
        argv = Shellwords.shellwords(merge_env_opts(task_config).to_full_args)
        begin
          TLDR::Run.cli(argv)
        rescue SystemExit => e
          fail "TLDR task #{name} failed with status #{e.status}" unless e.status == 0
        end
      end
    end

    def merge_env_opts task_config
      if ENV["TLDR_OPTS"]
        env_argv = Shellwords.shellwords(ENV["TLDR_OPTS"])
        opts_config = ArgvParser.new.parse(env_argv, {
          config_intended_for_merge_only: true
        })
        task_config.merge(opts_config)
      else
        task_config
      end
    end
  end
end

# Create the default tldr task for users
TLDR::Task.new
