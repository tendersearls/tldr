$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "tldr"
require "open3"

require "minitest/autorun"

module TLDRunner
  Result = Struct.new(:stdout, :stderr, :exit_code, :success?, keyword_init: true)

  def self.should_succeed(file, **config)
    run(file, config).tap do |result|
      if !result.success?
        raise <<~MSG
          Ran #{file} and expected success, but exited code #{result.exit_code}

          stdout:
          #{result.stdout}

          stderr:
          #{result.stderr}
        MSG
      end
    end
  end

  def self.should_fail(file, **config)
    run(file, config).tap do |result|
      if result.success?
        raise <<~MSG
          Ran #{file} and expected failure, but exited code #{result.exit_code}

          stdout:
          #{result.stdout}

          stderr:
          #{result.stderr}
        MSG
      end
    end
  end

  def self.run(file, config)
    stdout, stderr, status = Open3.capture3 <<~CMD
      bundle exec tldr #{File.expand_path("fixture/#{file}", __dir__)} #{"--seed #{config[:seed]}" if config.key?(:seed)}
    CMD

    Result.new(
      stdout: stdout.chomp,
      stderr: stderr.chomp,
      exit_code: status.exitstatus,
      success?: status.success?
    )
  end
end
