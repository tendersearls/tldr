$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "tldr"
require "open3"

require "minitest/autorun"

class Minitest::Test
  make_my_diffs_pretty!

  protected

  private

  def assert_includes_all haystack, needles
    unless needles.all? { |needle| haystack.include? needle }
      raise Minitest::Assertion, "Expected all of #{needles.inspect} to be found in in:\n\n---\n#{haystack}\n---"
    end
  end

  def assert_strings_appear_in_this_order haystack, needles
    og_haystack = haystack
    needles.each.with_index do |needle, i|
      index = haystack.index(needle)
      raise Minitest::Assertion, "#{needle.inspect} (string ##{i + 1} in #{needles.inspect}) not found in order in:\n\n---\n#{og_haystack}\n---" unless index

      haystack = haystack[(index + needle.length)..]
    end
  end

  def assert_these_appear_before_these haystack, before, after
    before.each.with_index do |needle, i|
      index = haystack.index(needle)

      if (after_needle = after.find { |after_needle| haystack.index(after_needle) < index })
        raise Minitest::Assertion, "#{needle.inspect} was expected to be found before #{after_needle.inspect} in:\n\n---\n#{haystack}\n---"
      end
    end
  end
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
