require "tldr"
TLDR::Run.at_exit!(TLDR::ArgvParser.new.parse(ARGV))
