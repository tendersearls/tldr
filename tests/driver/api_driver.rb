require "tldr"

TLDR::Run.tests(TLDR::Config.new(paths: ["tests/fixture/c.rb"], seed: 1))
