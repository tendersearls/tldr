require "optparse"

class TLDR
  class ArgvParser
    PATTERN_FRIENDLY_SPLITTER = /,(?=(?:[^\/]*\/[^\/]*\/)*[^\/]*$)/

    def parse args, options = {cli_defaults: true}
      og_args = args.dup
      OptionParser.new do |opts|
        opts.banner = "Usage: tldr [options] some_tests/**/*.rb some/path.rb:13 ..."

        opts.on "-t", "--[no-]timeout [TIMEOUT]", "Timeout (in seconds) before timer aborts the run (Default: #{Config::DEFAULT_TIMEOUT})" do |timeout|
          options[:timeout] = if timeout == false
            # --no-timeout
            -1
          elsif timeout.nil?
            # --timeout
            Config::DEFAULT_TIMEOUT
          else
            # --timeout 42.3
            handle_unparsable_optional_value(og_args, "timeout", timeout) do
              Float(timeout)
            end
          end
        end

        opts.on CONFLAGS[:watch], "Run your tests continuously on file save (requires 'fswatch' to be installed)" do
          options[:watch] = true
        end

        opts.on CONFLAGS[:fail_fast], "Stop running tests as soon as one fails" do |fail_fast|
          options[:fail_fast] = fail_fast
        end

        opts.on CONFLAGS[:parallel], "Parallelize tests (Default: true)" do |parallel|
          options[:parallel] = parallel
        end

        opts.on "-s", "#{CONFLAGS[:seed]} SEED", Integer, "Random seed for test order (setting --seed disables parallelization by default)" do |seed|
          options[:seed] = seed
        end

        opts.on "-n", "#{CONFLAGS[:names]} PATTERN", "One or more names or /patterns/ of tests to run (like: foo_test, /test_foo.*/, Foo#foo_test)" do |name|
          options[:names] ||= []
          options[:names] += name.split(PATTERN_FRIENDLY_SPLITTER)
        end

        opts.on "#{CONFLAGS[:exclude_names]} PATTERN", "One or more names or /patterns/ NOT to run" do |exclude_name|
          options[:exclude_names] ||= []
          options[:exclude_names] += exclude_name.split(PATTERN_FRIENDLY_SPLITTER)
        end

        opts.on "#{CONFLAGS[:exclude_paths]} PATH", Array, "One or more paths NOT to run (like: foo.rb, \"test/bar/**\", baz.rb:3)" do |path|
          options[:exclude_paths] ||= []
          options[:exclude_paths] += path
        end

        opts.on "#{CONFLAGS[:helper_paths]} PATH", Array, "One or more paths to a helper that is required before any tests (Default: \"test/helper.rb\")" do |path|
          options[:helper_paths] ||= []
          options[:helper_paths] += path
        end

        opts.on CONFLAGS[:no_helper], "Don't require any test helpers" do
          options[:no_helper] = true
        end

        opts.on "#{CONFLAGS[:prepend_paths]} PATH", Array, "Prepend one or more paths to run before the rest (Default: most recently modified test)" do |prepend|
          options[:prepend_paths] ||= []
          options[:prepend_paths] += prepend
        end

        opts.on CONFLAGS[:no_prepend], "Don't prepend any tests before the rest of the suite" do
          options[:no_prepend] = true
        end

        opts.on "-l", "#{CONFLAGS[:load_paths]} PATH", Array, "Add one or more paths to the $LOAD_PATH (Default: [\"lib\", \"test\"])" do |load_path|
          options[:load_paths] ||= []
          options[:load_paths] += load_path
        end

        opts.on "#{CONFLAGS[:base_path]} PATH", String, "Change the working directory for all relative paths (Default: current working directory)" do |path|
          options[:base_path] = path
        end

        opts.on "-c", "#{CONFLAGS[:config_path]} PATH", String, "The YAML configuration file to load (Default: '.tldr.yml')" do |config_path|
          options[:config_path] = config_path
        end

        opts.on "-r", "#{CONFLAGS[:reporter]} REPORTER", String, "Set a custom reporter class (Default: \"TLDR::Reporters::Default\")" do |reporter|
          options[:reporter] = reporter
        end

        opts.on CONFLAGS[:emoji], "Enable emoji output for the default reporter (Default: false)" do |emoji|
          options[:emoji] = emoji
        end

        opts.on CONFLAGS[:warnings], "Print Ruby warnings (Default: true)" do |warnings|
          options[:warnings] = warnings
        end

        opts.on "-v", CONFLAGS[:verbose], "Print stack traces for errors" do |verbose|
          options[:verbose] = verbose
        end

        opts.on CONFLAGS[:yes_i_know], "Suppress TLDR report when suite runs beyond any configured --timeout" do
          options[:yes_i_know] = true
        end

        opts.on CONFLAGS[:print_interrupted_test_backtraces], "Print stack traces of tests interrupted after a timeout" do |print_interrupted_test_backtraces|
          options[:print_interrupted_test_backtraces] = print_interrupted_test_backtraces
        end

        unless ARGV.include?("--help") || ARGV.include?("--h")
          opts.on CONFLAGS[:i_am_being_watched], "[INTERNAL] Signals to tldr it is being invoked under --watch mode" do
            options[:i_am_being_watched] = true
          end

          opts.on "--comment COMMENT", String, "[INTERNAL] No-op; used for multi-line execution instructions" do
            # See "--comment" in lib/tldr/reporters/default.rb for an example of how this is used internally
          end
        end
      end.parse!(args)

      options[:paths] = args if args.any?
      options[:config_path] = case options[:config_path]
      when nil then Config::DEFAULT_YAML_PATH
      when false then nil
      else options[:config_path]
      end

      Config.new(**options)
    end

    private

    def handle_unparsable_optional_value(og_args, option_name, value, &blk)
      yield
    rescue ArgumentError
      args = og_args.dup
      if (option_index = args.index("--#{option_name}"))
        args.insert(option_index + 1, "--")
        warn <<~MSG
          TLDR exited in error!

          We couldn't parse #{value.inspect} as a valid #{option_name} value

          Did you mean to set --#{option_name} as the last option and without an explicit value?

          If so, you need to append ' -- ' before any paths, like:

            tldr #{args.join(" ")}
        MSG
        exit 1
      else
        raise
      end
    end
  end
end
