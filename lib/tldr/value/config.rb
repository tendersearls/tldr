require "concurrent"

class TLDR
  CONFLAGS = {
    seed: "--seed",
    no_helper: "--no-helper",
    verbose: "--verbose",
    reporter: "--reporter",
    helper: "--helper",
    load_paths: "--load-path",
    workers: "--workers",
    names: "--name",
    fail_fast: "--fail-fast",
    no_emoji: "--no-emoji",
    prepend_tests: "--prepend",
    no_prepend: "--no-prepend",
    exclude_paths: "--exclude-path",
    exclude_names: "--exclude-name",
    paths: nil
  }.freeze

  PATH_FLAGS = [:paths, :helper, :load_paths, :prepend_tests, :exclude_paths].freeze
  MOST_RECENTLY_MODIFIED_TAG = "MOST_RECENTLY_MODIFIED".freeze

  Config = Struct.new :paths, :seed, :no_helper, :verbose, :reporter,
    :helper, :load_paths, :workers, :names, :fail_fast, :no_emoji,
    :prepend_tests, :no_prepend, :exclude_paths, :exclude_names,
    keyword_init: true do
    def initialize(*args)
      super
      self.paths ||= []
      self.load_paths ||= []
      self.names ||= []
      self.prepend_tests ||= []
      self.exclude_paths ||= []
      self.exclude_names ||= []
    end

    def self.build_defaults
      {
        paths: Dir["test/**/*_test.rb", "test/**/test_*.rb"],
        seed: rand(10_000),
        no_helper: false,
        verbose: false,
        reporter: Reporters::Default,
        helper: "test/helper.rb",
        load_paths: ["test"],
        workers: Concurrent.processor_count,
        names: [],
        fail_fast: false,
        no_emoji: false,
        prepend_tests: [MOST_RECENTLY_MODIFIED_TAG],
        no_prepend: false,
        exclude_paths: [],
        exclude_names: []
      }
    end

    def set_defaults!
      defaults = Config.build_defaults

      # Special cases
      if workers.nil?
        self.workers = seed.nil? ? defaults[:workers] : 1
      end

      # Arrays
      [:paths, :load_paths, :names, :prepend_tests, :exclude_paths, :exclude_names].each do |key|
        self[key] = defaults[key] if self[key].empty?
      end

      # Booleans
      [:no_helper, :verbose, :fail_fast, :no_emoji, :no_prepend].each do |key|
        self[key] = defaults[key] if self[key].nil?
      end

      # Values
      [:seed, :reporter, :helper].each do |key|
        self[key] ||= defaults[key]
      end
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
      }
    end

    def to_full_args(exclude: [])
      to_cli_argv(CONFLAGS.keys - exclude).join(" ")
    end

    def to_single_path_args(path)
      argv = to_cli_argv(CONFLAGS.keys - [
        :seed, :workers, :names, :fail_fast, :paths, :prepend_tests,
        :no_prepend, :exclude_paths
      ])

      (argv + [stringify(:paths, path)]).join(" ")
    end

    private

    def to_cli_argv(options = CONFLAGS.keys)
      defaults = Config.build_defaults
      options.map { |key|
        flag = CONFLAGS[key]

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
      tests.max_by { |test| File.mtime(test.file) }.file
    end
  end
end
