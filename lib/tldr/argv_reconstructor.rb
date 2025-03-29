class TLDR
  class ArgvReconstructor
    def reconstruct config, exclude:, ensure_args:, exclude_dotfile_matches:
      argv = to_cli_argv(
        config,
        CONFLAGS.keys - exclude - [
          (:seed unless config.seed_set_intentionally),
          :watch,
          :i_am_being_watched
        ],
        exclude_dotfile_matches:
      )

      ensure_args.each do |arg|
        argv << arg unless argv.include?(arg)
      end

      argv.join(" ")
    end

    def reconstruct_single_path_args config, path, exclude_dotfile_matches:
      argv = to_cli_argv(config, CONFLAGS.keys - [
        :seed, :parallel, :names, :fail_fast, :paths, :prepend_paths,
        :no_prepend, :exclude_paths, :watch, :i_am_being_watched
      ], exclude_dotfile_matches:)

      (argv + [stringify(:paths, path)]).join(" ")
    end

    private

    def to_cli_argv config, options = CONFLAGS.keys, exclude_dotfile_matches:
      defaults = Config.build_defaults(cli_defaults: true)
      defaults = defaults.merge(config.dotfile_args(config.config_path)) if exclude_dotfile_matches
      options.map { |key|
        flag = CONFLAGS[key]

        # Special cases
        if key == :prepend_paths
          if config.prepend_paths.map { |s| stringify(key, s) }.sort == config.paths.map { |s| stringify(:paths, s) }.sort
            # Don't print prepended tests if they're the same as the test paths
            next
          elsif config.no_prepend
            # Don't print prepended tests if they're disabled
            next
          end
        elsif key == :helper_paths && config.no_helper
          # Don't print the helper if it's disabled
          next
        elsif key == :parallel
          val = if !config.seed_set_intentionally && !config.parallel
            "--no-parallel"
          elsif !config.seed.nil? && config.seed_set_intentionally && config.parallel
            "--parallel"
          end
          next val
        elsif key == :timeout
          if config[:timeout] < 0
            next
          elsif config[:timeout] == Config::DEFAULT_TIMEOUT
            next "--timeout"
          elsif config[:timeout] != Config::DEFAULT_TIMEOUT
            next "--timeout #{config[:timeout]}"
          else
            next
          end
        elsif key == :config_path
          case config[:config_path]
          when nil then next "--no-config"
          when Config::DEFAULT_YAML_PATH then next
          else next "--config #{config[:config_path]}"
          end
        end

        if defaults[key] == config[key] && (key != :seed || !config.seed_set_intentionally)
          next
        elsif CONFLAGS[key]&.start_with?("--[no-]")
          case config[key]
          when false then CONFLAGS[key].gsub(/[\[\]]/, "")
          when nil || true then CONFLAGS[key].gsub("[no-]", "")
          else "#{CONFLAGS[key].gsub("[no-]", "")} #{stringify(key, config[key])}"
          end
        elsif config[key].is_a?(Array)
          config[key].map { |value| [flag, stringify(key, value)] }
        elsif config[key].is_a?(TrueClass) || config[key].is_a?(FalseClass)
          flag if config[key]
        elsif config[key].is_a?(Class)
          [flag, config[key].name]
        elsif !config[key].nil?
          [flag, stringify(key, config[key])]
        end
      }.flatten.compact
    end

    def stringify key, val
      if PATH_FLAGS.include?(key) && val.start_with?(Dir.pwd)
        val = val[Dir.pwd.length + 1..]
      end

      if val.nil? || val.is_a?(Integer)
        val
      else
        "\"#{val}\""
      end
    end
  end
end
