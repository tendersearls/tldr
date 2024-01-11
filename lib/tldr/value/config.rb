class TLDR
  CONFLAGS = {
    seed: "--seed",
    no_helper: "--no-helper",
    verbose: "--verbose",
    print_interrupted_test_backtraces: "--print-interrupted-test-backtraces",
    reporter: "--reporter",
    helper_paths: "--helper",
    load_paths: "--load-path",
    parallel: "--[no-]parallel",
    names: "--name",
    fail_fast: "--fail-fast",
    no_emoji: "--no-emoji",
    prepend_paths: "--prepend",
    no_prepend: "--no-prepend",
    exclude_paths: "--exclude-path",
    exclude_names: "--exclude-name",
    base_path: "--base-path",
    no_dotfile: "--no-dotfile",
    warnings: "--[no-]warnings",
    watch: "--watch",
    yes_i_know: "--yes-i-know",
    i_am_being_watched: "--i-am-being-watched",
    paths: nil
  }.freeze

  PATH_FLAGS = [:paths, :helper_paths, :load_paths, :prepend_paths, :exclude_paths].freeze
  MOST_RECENTLY_MODIFIED_TAG = "MOST_RECENTLY_MODIFIED".freeze
  CONFIG_ATTRIBUTES = [
    :paths, :seed, :no_helper, :verbose, :print_interrupted_test_backtraces, :reporter,
    :helper_paths, :load_paths, :parallel, :names, :fail_fast, :no_emoji,
    :prepend_paths, :no_prepend, :exclude_paths, :exclude_names, :base_path,
    :no_dotfile, :warnings, :watch, :yes_i_know, :i_am_being_watched,
    # Internal properties
    :config_intended_for_merge_only, :seed_set_intentionally, :cli_defaults
  ].freeze

  Config = Struct.new(*CONFIG_ATTRIBUTES, keyword_init: true) do
    def initialize(**args)
      original_base_path = Dir.pwd
      unless args[:config_intended_for_merge_only]
        change_working_directory_because_i_am_bad_and_i_should_feel_bad!(args[:base_path])
        args = merge_dotfile_args(args) unless args[:no_dotfile]
      end
      args = undefault_parallel_if_seed_set(args)
      unless args[:config_intended_for_merge_only]
        args = merge_defaults(args)
        revert_working_directory_change_because_itll_ruin_everything!(original_base_path)
      end

      super(**args)
    end

    # These are for internal tracking and resolved at initialization-time
    undef_method :config_intended_for_merge_only=, :seed_set_intentionally=,
      # These must be set when the Config is first initialized
      :cli_defaults=, :no_dotfile=, :base_path=

    def self.build_defaults cli_defaults: true
      common = {
        seed: rand(10_000),
        no_helper: false,
        verbose: false,
        print_interrupted_test_backtraces: false,
        reporter: Reporters::Default,
        parallel: true,
        names: [],
        fail_fast: false,
        no_emoji: false,
        no_prepend: false,
        exclude_paths: [],
        exclude_names: [],
        base_path: nil,
        warnings: true,
        watch: false,
        yes_i_know: false,
        i_am_being_watched: false
      }

      if cli_defaults
        common.merge(
          paths: Dir["test/**/*_test.rb", "test/**/test_*.rb"],
          helper_paths: ["test/helper.rb"],
          load_paths: ["lib", "test"],
          prepend_paths: [MOST_RECENTLY_MODIFIED_TAG]
        )
      else
        common.merge(
          paths: [],
          helper_paths: [],
          load_paths: [],
          prepend_paths: []
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
      [:paths, :helper_paths, :load_paths, :names, :prepend_paths, :exclude_paths, :exclude_names].each do |key|
        merged_args[key] = defaults[key] if merged_args[key].nil? || merged_args[key].empty?
      end

      # Booleans
      [:no_helper, :verbose, :print_interrupted_test_backtraces, :fail_fast, :no_emoji, :no_prepend, :warnings, :yes_i_know, :i_am_being_watched].each do |key|
        merged_args[key] = defaults[key] if merged_args[key].nil?
      end

      # Values
      [:seed, :reporter].each do |key|
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
      defaults = defaults.merge(dotfile_args) if exclude_dotfile_matches
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
      return args if args[:no_dotfile]

      dotfile_args.merge(args)
    end

    def dotfile_args
      return {} unless File.exist?(".tldr.yml")

      require "yaml"
      @dotfile_args ||= YAML.load_file(".tldr.yml").transform_keys { |k| k.to_sym }.tap do |dotfile_args|
        # Since we don't have shell expansion, we have to glob any paths ourselves
        if dotfile_args.key?(:paths)
          dotfile_args[:paths] = dotfile_args[:paths].flat_map { |path| Dir[path] }
        end
        # The argv parser normally does this:
        if dotfile_args.key?(:reporter)
          dotfile_args[:reporter] = Kernel.const_get(dotfile_args[:reporter])
        end
        if (invalid_args = dotfile_args.except(*CONFIG_ATTRIBUTES)).any?
          raise Error, "Invalid keys in .tldr.yml file: #{invalid_args.keys.join(", ")}"
        end
      end
    end
  end
end
