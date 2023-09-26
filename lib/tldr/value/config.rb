class TLDR
  CONFLAGS = {
    seed: "--seed",
    no_helper: "--no-helper",
    verbose: "--verbose",
    reporter: "--reporter",
    helper: "--helper",
    load_paths: "--load-path",
    parallel: "--[no-]parallel",
    names: "--name",
    fail_fast: "--fail-fast",
    no_emoji: "--no-emoji",
    prepend_tests: "--prepend",
    no_prepend: "--no-prepend",
    exclude_paths: "--exclude-path",
    exclude_names: "--exclude-name",
    base_path: "--base-path",
    no_dotfile: "--no-dotfile",
    paths: nil
  }.freeze

  PATH_FLAGS = [:paths, :helper, :load_paths, :prepend_tests, :exclude_paths].freeze
  MOST_RECENTLY_MODIFIED_TAG = "MOST_RECENTLY_MODIFIED".freeze

  Config = Struct.new :paths, :seed, :no_helper, :verbose, :reporter,
    :helper, :load_paths, :parallel, :names, :fail_fast, :no_emoji,
    :prepend_tests, :no_prepend, :exclude_paths, :exclude_names, :base_path,
    :no_dotfile,
    :seed_set_intentionally, :cli_mode, keyword_init: true do
    def initialize(**args)
      change_working_directory_because_i_am_bad_and_i_should_feel_bad!(args[:base_path])
      args = merge_dotfile_args(args) unless args[:no_dotfile]

      super(**merge_defaults(args))
    end

    # Must be set when the Config is first initialized
    undef_method :cli_mode=, :no_dotfile=, :base_path=

    def self.build_defaults(cli_mode = false)
      common = {
        seed: rand(10_000),
        no_helper: false,
        verbose: false,
        reporter: Reporters::Default,
        parallel: true,
        names: [],
        fail_fast: false,
        no_emoji: false,
        no_prepend: false,
        exclude_paths: [],
        exclude_names: [],
        base_path: nil
      }

      if cli_mode
        common.merge(
          paths: Dir["test/**/*_test.rb", "test/**/test_*.rb"],
          helper: "test/helper.rb",
          load_paths: ["test"],
          prepend_tests: [MOST_RECENTLY_MODIFIED_TAG]
        )
      else
        common.merge(
          paths: [],
          helper: nil,
          load_paths: [],
          prepend_tests: []
        )
      end
    end

    def merge_defaults(user_args)
      merged_args = user_args.dup
      defaults = Config.build_defaults(merged_args[:cli_mode])
      merged_args[:seed_set_intentionally] = !merged_args[:seed].nil?

      # Special cases
      if merged_args[:parallel].nil?
        # Disable parallelization if seed is set
        merged_args[:parallel] = merged_args[:seed].nil?
      end

      # Arrays
      [:paths, :load_paths, :names, :prepend_tests, :exclude_paths, :exclude_names].each do |key|
        merged_args[key] = defaults[key] if merged_args[key].nil? || merged_args[key].empty?
      end

      # Booleans
      [:no_helper, :verbose, :fail_fast, :no_emoji, :no_prepend].each do |key|
        merged_args[key] = defaults[key] if merged_args[key].nil?
      end

      # Values
      [:seed, :reporter, :helper].each do |key|
        merged_args[key] ||= defaults[key]
      end

      merged_args
    end

    # We needed this hook (to be called by the planner), because we can't know
    # the default prepend location until we have all the resolved test paths,
    # so we have to mutate it after the fact.
    def update_after_gathering_tests! tests
      return unless prepend_tests.include?(MOST_RECENTLY_MODIFIED_TAG)

      self.prepend_tests = prepend_tests.map { |path|
        if path == MOST_RECENTLY_MODIFIED_TAG
          most_recently_modified_test_file tests
        else
          path
        end
      }.compact
    end

    def to_full_args(exclude: [])
      to_cli_argv(CONFLAGS.keys - exclude).join(" ")
    end

    def to_single_path_args(path)
      argv = to_cli_argv(CONFLAGS.keys - [
        :seed, :parallel, :names, :fail_fast, :paths, :prepend_tests,
        :no_prepend, :exclude_paths
      ])

      (argv + [stringify(:paths, path)]).join(" ")
    end

    private

    def to_cli_argv(options = CONFLAGS.keys)
      defaults = Config.build_defaults(cli_mode)
      options.map { |key|
        flag = CONFLAGS[key]

        # Special cases
        if key == :prepend_tests
          if prepend_tests.map { |s| stringify(key, s) }.sort == paths.map { |s| stringify(:paths, s) }.sort
            # Don't print prepended tests if they're the same as the test paths
            next
          elsif no_prepend
            # Don't print prepended tests if they're disabled
            next
          end
        elsif key == :helper && no_helper
          # Don't print the helper if it's disabled
          next
        elsif key == :parallel
          val = if !seed_set_intentionally && !parallel
            "--no-parallel"
          elsif !seed.nil? && seed_set_intentionally && parallel
            "--parallel"
          end
          next val
        end

        if defaults[key] == self[key]
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

    def most_recently_modified_test_file(tests)
      return if tests.empty?

      tests.max_by { |test| File.mtime(test.file) }.file
    end

    # If the user sets a custom base path, we need to change the working directory
    # ASAP, even before globbing to find default paths of tests. If there is
    # a way to change all of our Dir.glob calls to be relative to base_path
    # without a loss in accuracy, would love to not have to use Dir.chdir!
    def change_working_directory_because_i_am_bad_and_i_should_feel_bad!(base_path)
      Dir.chdir(base_path) unless base_path.nil?
    end

    def merge_dotfile_args(args)
      return args if args[:no_dotfile] || !File.exist?(".tldr.yml")
      require "yaml"

      dotfile_args = YAML.load_file(".tldr.yml").transform_keys { |k| k.to_sym }
      # Since we don't have shell expansion, we have to glob any paths ourselves
      if dotfile_args.key?(:paths)
        dotfile_args[:paths] = dotfile_args[:paths].flat_map { |path| Dir[path] }
      end
      # The argv parser normally does this:
      if dotfile_args.key?(:reporter)
        dotfile_args[:reporter] = Kernel.const_get(dotfile_args[:reporter])
      end

      dotfile_args.merge(args)
    end
  end
end
