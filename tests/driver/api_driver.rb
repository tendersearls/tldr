require "tldr"

TLDR::API.run(TLDR::Config.new(paths: ["tests/fixture/c.rb"], seed: 1))
