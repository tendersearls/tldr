$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "tldr"
require "open3"

require "minitest/autorun"

class Minitest::Test
  make_my_diffs_pretty!
end

module TLDRunner
  Result = Struct.new(:stdout, :stderr, :exit_code, :success?, keyword_init: true)

  def self.should_succeed files, options = nil
    run(files, options).tap do |result|
      if !result.success?
        raise <<~MSG
          Ran #{files.inspect} and expected success, but exited code #{result.exit_code}

          stdout:
          #{result.stdout}

          stderr:
          #{result.stderr}
        MSG
      end
    end
  end

  def self.should_fail files, options = nil
    run(files, options).tap do |result|
      if result.success?
        raise <<~MSG
          Ran #{files.inspect} and expected failure, but exited code #{result.exit_code}

          stdout:
          #{result.stdout}

          stderr:
          #{result.stderr}
        MSG
      end
    end
  end

  def self.run files, options
    files = Array(files).map { |file| File.expand_path("fixture/#{file}", __dir__) }

    stdout, stderr, status = Open3.capture3 <<~CMD
      bundle exec tldr #{files.join(" ")} #{options}
    CMD

    Result.new(
      stdout: stdout.chomp,
      stderr: stderr.chomp,
      exit_code: status.exitstatus,
      success?: status.success?
    )
  end
end
