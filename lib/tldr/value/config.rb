require "concurrent"

class TLDR
  Config = Struct.new :paths, :seed, :skip_test_helper, :verbose, :reporter, :helper, :load_paths, :workers, :names, keyword_init: true do
    def initialize(*args)
      super
      self.paths ||= []
      self.load_paths ||= []
      self.names ||= []
    end

    def set_defaults!
      self.paths = Dir["test/**/*_test.rb", "test/**/test_*.rb"] if paths.empty?
      self.seed ||= rand(10_000)
      self.skip_test_helper = false if skip_test_helper.nil?
      self.verbose = false if verbose.nil?
      self.reporter ||= Reporters::Default.new
      self.helper ||= "test/helper.rb"
      self.load_paths = ["test"] if load_paths.empty?
      self.workers ||= Concurrent.processor_count
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
