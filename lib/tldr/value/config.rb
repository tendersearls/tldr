require "concurrent"

class TLDR
  CONFLAGS = {
    seed: "--seed",
    skip_test_helper: "--skip-test-helper",
    verbose: "--verbose",
    reporter: "--reporter",
    helper: "--helper",
    load_paths: "--load-path",
    workers: "--workers",
    names: "--name",
    fail_fast: "--fail-fast",
    paths: nil
  }.freeze

  Config = Struct.new :paths, :seed, :skip_test_helper, :verbose, :reporter,
    :helper, :load_paths, :workers, :names, :fail_fast,
    keyword_init: true do
    def initialize(*args)
      super
      self.paths ||= []
      self.load_paths ||= []
      self.names ||= []
    end

    def self.build_defaults
      {
        paths: Dir["test/**/*_test.rb", "test/**/test_*.rb"],
        seed: rand(10_000),
        skip_test_helper: false,
        verbose: false,
        reporter: Reporters::Default.new,
        helper: "test/helper.rb",
        load_paths: ["test"],
        workers: Concurrent.processor_count,
        names: [],
        fail_fast: false
      }
    end

    def set_defaults!
      defaults = Config.build_defaults

      [:paths, :load_paths, :names].each do |key|
        self[key] = defaults[key] if self[key].empty?
      end

      [:skip_test_helper, :verbose, :fail_fast].each do |key|
        self[key] = defaults[key] if self[key].nil?
      end

      [:seed, :reporter, :helper, :workers].each do |key|
        self[key] ||= defaults[key]
      end
    end

    def to_full_args
      to_cli_argv.join(" ")
    end

    def to_single_path_args(path)
      argv = to_cli_argv(CONFLAGS.keys - [
        :seed, :workers, :names, :fail_fast, :paths
      ])

      (argv + [bad_escape(path)]).join(" ")
    end

    private

    def to_cli_argv(options = CONFLAGS.keys)
      defaults = Config.build_defaults
      options.map { |key|
        flag = CONFLAGS[key]

        if defaults[key] == self[key]
          next
        elsif self[key].is_a?(Array)
          self[key].map { |value| [flag, bad_escape(value)] }
        elsif self[key].is_a?(TrueClass) || self[key].is_a?(FalseClass)
          flag if self[key]
        elsif self[key].is_a?(Reporters::Base)
          [flag, self[key].class.name] unless self[key].is_a?(Reporters::Default)
        elsif !self[key].nil?
          [flag, bad_escape(self[key])]
        end
      }.flatten.compact
    end

    def bad_escape val
      if val.nil? || val.is_a?(Integer)
        val
      else
        "\"#{val}\""
      end
    end
  end
end
