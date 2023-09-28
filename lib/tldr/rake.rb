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
        cli_args = build_cli_args(task_config)
        fail unless system "#{"bundle exec " if defined?(Bundler)}tldr #{cli_args}"
      end
    end

    def build_cli_args task_config
      config = if ENV["TLDR_OPTS"]
        env_argv = Shellwords.shellwords(ENV["TLDR_OPTS"])
        opts_config = ArgvParser.new.parse(env_argv, {
          config_intended_for_merge_only: true
        })
        task_config.merge(opts_config)
      else
        task_config
      end

      config.to_full_args
    end
  end
end

# Create the default tldr task for users
TLDR::Task.new
