$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "tldr"
require "open3"

require "minitest/autorun"

module TLDRunner
  Result = Struct.new(:stdout, :stderr, :exit_code, :success?, keyword_init: true)

  def self.run(file)
    stdout, stderr, status = Open3.capture3 <<~CMD
      ruby -e '
        $LOAD_PATH.unshift("#{File.expand_path("../lib", __dir__)}");
        require "tldr"; require "#{File.expand_path("fixture/#{file}", __dir__)}";
        TLDR.plan.run!
      '
    CMD

    Result.new(
      stdout: stdout.chomp,
      stderr: stderr.chomp,
      exit_code: status.to_i,
      success?: status.success?
    )
  end
end
