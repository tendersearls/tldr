class TLDR
  CONFLAGS = {
    fail_fast: "--fail-fast",
    seed: "--seed",
    parallel: "--[no-]parallel",
    timeout: "--[no-]timeout",
    names: "--name",
    exclude_names: "--exclude-name",
    exclude_paths: "--exclude-path",
    helper_paths: "--helper",
    no_helper: "--no-helper",
    prepend_paths: "--prepend",
    no_prepend: "--no-prepend",
    load_paths: "--load-path",
    reporter: "--reporter",
    base_path: "--base-path",
    config_path: "--[no-]config",
    no_emoji: "--no-emoji",
    verbose: "--verbose",
    print_interrupted_test_backtraces: "--print-interrupted-test-backtraces",
    warnings: "--[no-]warnings",
    watch: "--watch",
    yes_i_know: "--yes-i-know",
    i_am_being_watched: "--i-am-being-watched",
    paths: nil
  }.freeze

  PATH_FLAGS = [:paths, :helper_paths, :load_paths, :prepend_paths, :exclude_paths].freeze
  MOST_RECENTLY_MODIFIED_TAG = "MOST_RECENTLY_MODIFIED".freeze
  CONFIG_ATTRIBUTES = [
    :fail_fast, :seed, :parallel, :timeout, :no_timeout, :names, :exclude_names,
    :exclude_paths, :helper_paths, :no_helper, :prepend_paths, :no_prepend,
    :load_paths, :reporter, :base_path, :config_path, :no_emoji, :verbose,
    :print_interrupted_test_backtraces, :warnings, :watch, :yes_i_know,
    :i_am_being_watched, :paths,
    # Internal properties
    :config_intended_for_merge_only, :seed_set_intentionally, :cli_defaults
  ].freeze

  Config = Struct.new(*CONFIG_ATTRIBUTES, keyword_init: true) do
    def initialize(**args)
      original_base_path = Dir.pwd
      unless args[:config_intended_for_merge_only]
        change_working_directory_because_i_am_bad_and_i_should_feel_bad!(args[:base_path])
        args = merge_dotfile_args(args) unless args[:config_path].nil?
      end
      args = undefault_parallel_if_seed_set(args)
      unless args[:config_intended_for_merge_only]
        args = merge_defaults(args)
        revert_working_directory_change_because_itll_ruin_everything!(original_base_path)
      end

      super
    end

    # These are for internal tracking and resolved at initialization-time
    undef_method :config_intended_for_merge_only=, :seed_set_intentionally=,
      # These must be set when the Config is first initialized
      :cli_defaults=, :config_path=, :base_path=

    def self.build_defaults cli_defaults: true
      common = {
        fail_fast: false,
        seed: rand(10_000),
        parallel: true,
        timeout: -1,
        names: [],
        exclude_names: [],
        exclude_paths: [],
        no_helper: false,
        no_prepend: false,
        reporter: Reporters::Default,
        base_path: nil,
        no_emoji: false,
        verbose: false,
        print_interrupted_test_backtraces: false,
        warnings: true,
        watch: false,
        yes_i_know: false,
        i_am_being_watched: false
      }

      if cli_defaults
        common.merge(
          helper_paths: ["test/helper.rb"],
          prepend_paths: [MOST_RECENTLY_MODIFIED_TAG],
          load_paths: ["lib", "test"],
          config_path: nil,
          paths: Dir["test/**/*_test.rb", "test/**/test_*.rb"]
        )
      else
        common.merge(
          helper_paths: [],
          prepend_paths: [],
          load_paths: [],
          config_path: Config::DEFAULT_YAML_PATH, # ArgvParser#parse will set this default and if it sets nil that is intentionally blank b/c --no-config
          paths: []
        )
      end
    end

    def undefault_parallel_if_seed_set args
      args.merge(
        seed_set_intentionally: !args[:seed].nil?,
        parallel: (args[:parallel].nil? ? args[:seed].nil? : args[:parallel])
      )
    end

    def merge_defaults user_args
      merged_args = user_args.dup
      defaults = Config.build_defaults(cli_defaults: merged_args[:cli_defaults])

      # Arrays
      [:names, :exclude_names, :exclude_paths, :helper_paths, :prepend_paths, :load_paths, :paths].each do |key|
        merged_args[key] = defaults[key] if merged_args[key].nil? || merged_args[key].empty?
      end

      # Booleans
      [:fail_fast, :parallel, :no_helper, :no_prepend, :no_emoji, :verbose, :print_interrupted_test_backtraces, :warnings, :watch, :yes_i_know, :i_am_being_watched].each do |key|
        merged_args[key] = defaults[key] if merged_args[key].nil?
      end

      # Values
      [:seed, :timeout, :reporter, :base_path, :config_path].each do |key|
        merged_args[key] ||= defaults[key]
      end

      merged_args
    end

    def merge other
      this_config = to_h
      kwargs = this_config.merge(
        other.to_h.compact.except(:config_intended_for_merge_only)
      )
      Config.new(**kwargs)
    end

    # We needed this hook (to be called by the planner), because we can't know
    # the default prepend location until we have all the resolved test paths,
    # so we have to mutate it after the fact.
    def update_after_gathering_tests! tests
      return unless prepend_paths.include?(MOST_RECENTLY_MODIFIED_TAG)

      self.prepend_paths = prepend_paths.map { |path|
        if path == MOST_RECENTLY_MODIFIED_TAG
          most_recently_modified_test_file(tests)
        else
          path
        end
      }.compact
    end

    def to_full_args exclude: [], ensure_args: [], exclude_dotfile_matches: false
      argv = to_cli_argv(
        CONFLAGS.keys - exclude - [
          (:seed unless seed_set_intentionally),
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

    def to_single_path_args path, exclude_dotfile_matches: false
      argv = to_cli_argv(CONFLAGS.keys - [
        :seed, :parallel, :names, :fail_fast, :paths, :prepend_paths,
        :no_prepend, :exclude_paths, :watch, :i_am_being_watched
      ], exclude_dotfile_matches:)

      (argv + [stringify(:paths, path)]).join(" ")
    end

    private

    def to_cli_argv options = CONFLAGS.keys, exclude_dotfile_matches:
      defaults = Config.build_defaults(cli_defaults: true)
      defaults = defaults.merge(dotfile_args(config_path)) if exclude_dotfile_matches
      options.map { |key|
        flag = CONFLAGS[key]

        # Special cases
        if key == :prepend_paths
          if prepend_paths.map { |s| stringify(key, s) }.sort == paths.map { |s| stringify(:paths, s) }.sort
            # Don't print prepended tests if they're the same as the test paths
            next
          elsif no_prepend
            # Don't print prepended tests if they're disabled
            next
          end
        elsif key == :helper_paths && no_helper
          # Don't print the helper if it's disabled
          next
        elsif key == :parallel
          val = if !seed_set_intentionally && !parallel
            "--no-parallel"
          elsif !seed.nil? && seed_set_intentionally && parallel
            "--parallel"
          end
          next val
        elsif key == :timeout
          if self[:timeout] < 0
            next
          elsif self[:timeout] == Config::DEFAULT_TIMEOUT
            next "--timeout"
          elsif self[:timeout] != Config::DEFAULT_TIMEOUT
            next "--timeout #{self[:timeout]}"
          else
            next
          end
        elsif key == :config_path
          case self[:config_path]
          when nil then next "--no-config"
          when Config::DEFAULT_YAML_PATH then next
          else next "--config #{self[:config_path]}"
          end
        elsif key == :warnings && defaults[:warnings] != self[:warnings]
          next warnings ? "--warnings" : "--no-warnings"
        end

        if defaults[key] == self[key] && (key != :seed || !seed_set_intentionally)
          next
        elsif self[key].is_a?(Array)
          self[key].map { |value| [flag, stringify(key, value)] }
        elsif self[key].is_a?(TrueClass) || self[key].is_a?(FalseClass)
          flag if self[key]
        elsif self[key].is_a?(Class)
          [flag, self[key].name]
        elsif !self[key].nil?
          [flag, stringify(key, self[key])]
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

    def most_recently_modified_test_file tests
      return if tests.empty?

      tests.max_by { |test| File.mtime(test.file) }.file
    end

    # If the user sets a custom base path, we need to change the working directory
    # ASAP, even before globbing to find default paths of tests. If there is
    # a way to change all of our Dir.glob calls to be relative to base_path
    # without a loss in accuracy, would love to not have to use Dir.chdir!
    def change_working_directory_because_i_am_bad_and_i_should_feel_bad! base_path
      Dir.chdir(base_path) unless base_path.nil?
    end

    def revert_working_directory_change_because_itll_ruin_everything! original_base_path
      Dir.chdir(original_base_path) unless Dir.pwd == original_base_path
    end

    def merge_dotfile_args args
      dotfile_args(args[:config_path]).merge(args)
    end

    def dotfile_args config_path
      return {} unless File.exist?(config_path)

      @dotfile_args ||= YamlParser.new.parse(config_path)
    end
  end

  Config::DEFAULT_YAML_PATH = ".tldr.yml"
  Config::DEFAULT_TIMEOUT = 1.8
end
