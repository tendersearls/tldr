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
    fail_fast: "--fail-fast"
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
      [
        "--seed #{seed}",
        ("--skip-test-helper" if skip_test_helper)
      ].join(" ")
    end

    def to_single_args
      [
        ("--skip-test-helper" if skip_test_helper)
      ].join(" ")
    end
  end
end
