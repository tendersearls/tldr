class TLDR
  CONFLAGS = {
    timeout: "--[no-]timeout",
    watch: "--watch",
    fail_fast: "--fail-fast",
    parallel: "--[no-]parallel",
    seed: "--seed",
    names: "--name",
    exclude_names: "--exclude-name",
    exclude_paths: "--exclude-path",
    helper_paths: "--helper",
    no_helper: "--no-helper",
    prepend_paths: "--prepend",
    no_prepend: "--no-prepend",
    load_paths: "--load-path",
    base_path: "--base-path",
    config_path: "--[no-]config",
    reporter: "--reporter",
    emoji: "--[no-]emoji",
    warnings: "--[no-]warnings",
    verbose: "--verbose",
    yes_i_know: "--yes-i-know",
    print_interrupted_test_backtraces: "--print-interrupted-test-backtraces",
    i_am_being_watched: "--i-am-being-watched",
    exit_0_on_timeout: "--exit-0-on-timeout",
    exit_2_on_failure: "--exit-2-on-failure",
    paths: nil
  }.freeze

  PATH_FLAGS = [:paths, :helper_paths, :load_paths, :prepend_paths, :exclude_paths].freeze
  MOST_RECENTLY_MODIFIED_TAG = "MOST_RECENTLY_MODIFIED".freeze
  CONFIG_ATTRIBUTES = [
    :timeout, :watch, :fail_fast, :parallel, :seed, :names, :exclude_names,
    :exclude_paths, :helper_paths, :no_helper, :prepend_paths, :no_prepend,
    :load_paths, :base_path, :config_path, :reporter, :emoji, :warnings,
    :verbose, :yes_i_know, :print_interrupted_test_backtraces,
    :i_am_being_watched, :exit_0_on_timeout, :exit_2_on_failure, :paths,
    # Internal properties
    :config_intended_for_merge_only, :seed_set_intentionally, :cli_defaults
  ].freeze

  Config = Struct.new(*CONFIG_ATTRIBUTES, keyword_init: true) do
    def initialize(**args)
      @argv_reconstructor = ArgvReconstructor.new

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
        timeout: -1,
        watch: false,
        fail_fast: false,
        parallel: true,
        seed: rand(10_000),
        names: [],
        exclude_names: [],
        exclude_paths: [],
        no_helper: false,
        no_prepend: false,
        base_path: nil,
        reporter: "TLDR::Reporters::Default",
        emoji: false,
        warnings: true,
        verbose: false,
        yes_i_know: false,
        print_interrupted_test_backtraces: false,
        i_am_being_watched: false,
        exit_0_on_timeout: false,
        exit_2_on_failure: false
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
        parallel: (args[:parallel].nil? ? args[:seed].nil? : args[:parallel]),
        seed_set_intentionally: !args[:seed].nil?
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
      [:watch, :fail_fast, :parallel, :no_helper, :no_prepend, :emoji, :warnings, :verbose, :yes_i_know, :print_interrupted_test_backtraces, :i_am_being_watched, :exit_0_on_timeout, :exit_2_on_failure].each do |key|
        merged_args[key] = defaults[key] if merged_args[key].nil?
      end

      # Values
      [:timeout, :seed, :base_path, :config_path, :reporter].each do |key|
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
      @argv_reconstructor.reconstruct(self, exclude:, ensure_args:, exclude_dotfile_matches:)
    end

    def to_single_path_args path, exclude_dotfile_matches: false
      @argv_reconstructor.reconstruct_single_path_args(self, path, exclude_dotfile_matches:)
    end

    def dotfile_args config_path
      return {} unless File.exist?(config_path)

      @dotfile_args ||= YamlParser.new.parse(config_path)
    end

    private

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
  end

  Config::DEFAULT_YAML_PATH = ".tldr.yml"
  Config::DEFAULT_TIMEOUT = 1.8
end
