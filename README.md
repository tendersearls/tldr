# TLDR - for people who don't have time for slow tests

Okay, you might need to sit down for this:

**tl;dr, TLDR is a Ruby test framework that stops running your tests after 1.8 seconds.**

We initially meant this as a joke [while
pairin'](https://www.youtube.com/live/bmi-SWeH4MA?si=p5g1j1FQZrbYEOCg&t=63), but
in addition to being funny, it was also a pretty good idea. So we fleshed out
`tldr` to be a full-featured, mostly
[Minitest-compatible](#minitest-compatibility), and downright pleasant test
framework for Ruby.

The "big idea" here is TLDR is designed for users to run the `tldr` command
repeatedly as they work—as opposed to only running the tests for whatever is
being worked on. Even if the suite run over the 1.8 second time limit. Because
TLDR shuffles and runs in parallel and is guaranteed to take less than two
seconds,
**you'll actually wind up running _all_ of your tests quite often as you work**,
catching any problems much earlier than if you had waited until the end of the
day to push your work and let a continuous integration server run the full
suite.

Some stuff you might like:

* A CLI that can run tests by line number(s) (e.g. `foo.rb:5 bar.rb:3:10`) and
by names or patterns (e.g. `--name test_fail,test_error --name "/_\d/"`)
* Everything is **parallel by default**, and seems pretty darn fast; TLDR
also provides [several escape hatches to sequester tests that aren't thread-safe](#parallel-by-default-is-nice-in-theory-but-half-my-tests-are-failing-wat)
* Surprisingly delightful color diff output when two things fail to equal one
another, care of [@mcmire's super_diff gem](https://github.com/mcmire/super_diff)
* By default, the CLI will prepend your most-recently-edited test file to the
front of your suite so its tests will run first. The test you worked on most recently
is the one you most likely want to ensure runs, so TLDR runs it first (see the
`--prepend` option for how to control this behavior)
* And, of course, our signature feature: your test suite will never grow into
a glacially slow, soul-sucking albatross around your neck, because **after 1.8
seconds, it stops running your tests**, with a report on what it _was_ able to
run and where your slowest tests are

Some stuff you might _not_ like:

* The thought of switching Ruby test frameworks in 2023
* That bit about your test suite exploding after 1.8 seconds

## Install

Either `gem install tldr` or add it to your Gemfile:

```
gem "tldr"
```

## Usage

Here's what a test looks like:

```ruby
class MathTest < TLDR
  def test_adding
    assert_equal 1 + 1, 2
  end
end
```

A TLDR subclass defines its tests with instance methods that begin with
`test_`. They can define `setup` and/or `teardown` methods which will run before
and after each test, respectively.

If you place your tests in `test/**/*_test.rb` (and/or `test/**/test_*.rb`)
files, the `tldr` executable will find them automatically.  And if you define a
`test/helper.rb` file, it will be loaded prior to your tests.

Running the CLI is pretty straightforward:

```
$ tldr
```

You can, of course, also just run a specific test file or glob:

```
$ tldr test/this/one/in/particular.rb
```

Or specify the line numbers of tests to run by appending them after a `:`

```
$ tldr test/fixture/line_number.rb:3:10
```

And filter which tests run by name or pattern with one or more `--name` or `-n`
flags:

```
$ tldr --name FooTest#test_foo -n test_bar,test_baz -n /_qux/
```

(The above will translate to this array of name filters internally:
 `["FooTest#test_foo", "test_bar", "test_baz", "/_qux/"]`.)

### Options

Here is the full list of CLI options:

```
$ tldr --help
Usage: tldr [options] some_tests/**/*.rb some/path.rb:13 ...
        --fail-fast                  Stop running tests as soon as one fails
    -s, --seed SEED                  Seed for randomization
        --[no-]parallel              Parallelize tests (Default: true)
    -n, --name PATTERN               One or more names or /patterns/ of tests to run (like: foo_test, /test_foo.*/, Foo#foo_test)
        --exclude-name PATTERN       One or more names or /patterns/ NOT to run
        --exclude-path PATH          One or more paths NOT to run (like: foo.rb, "test/bar/**", baz.rb:3)
        --helper HELPER              Path to a test helper to load before any tests (Default: "test/helper.rb")
        --no-helper                  Don't try loading a test helper before the tests
        --prepend PATH               Prepend one or more paths to run before the rest (Default: most recently modified test)
        --no-prepend                 Don't prepend any tests before the rest of the suite
    -l, --load-path PATH             Add one or more paths to the $LOAD_PATH (Default: ["test"])
    -r, --reporter REPORTER          Set a custom reporter class (Default: "TLDR::Reporters::Default")
        --base-path PATH             Change the working directory for all relative paths (Default: current working directory)
        --no-dotfile                 Disable loading .tldr.yml dotfile
        --no-emoji                   Disable emoji in the output
    -v, --verbose                    Print stack traces for errors
        --comment COMMENT            No-op comment, used internally for multi-line execution instructions
```

After being parsed, all the CLI options are converted into a
[TLDR::Config](/lib/tldr/value/config.rb) object.

### Setting defaults in .tldr.yml

The `tldr` CLI will look for a `.tldr.yml` file in your project root (your
working directory or whatever `--base-path` you set), which can contain values
for any properties on [TLDR::Config](/lib/tldr/value/config.rb) (with the
exception of `--base-path` itself).

Any values found in the dotfile will override TLDR's built-in values, but can
still be specified by the `tldr` CLI or a `TLDR::Config` object passed to
[TLDR::Run.at_exit!](#running-tests-without-the-cli).

Here's an [example project](/example/c) that specifies a `.tldr.yml` file as
well as some [internal tests](/tests/dotfile_test.rb) demonstrating its behavior.

### Minitest compatibility

Tests you write with tldr are designed to be mostly-compatible with
[Minitest](https://github.com/minitest/minitest) tests. Some notes:

* `setup` and `teardown` hook methods should work as you expect. (We even threw
in [an `around` hook](https://github.com/splattael/minitest-around) as a bonus!)
* All of Minitest's assertions (e.g. `assert`, `assert_equals`) are provided,
with these caveats:
  * To retain the `expected, actual` argument ordering, `tldr` defines
  `assert_include?(element, container)` instead of
  `assert_includes(container, element)`
  * If you want to maximize compatibility and mix in `assert_includes` and the
  deprecated `assert_send`, just `include
  TLDR::Assertions::MinitestCompatibility` into the `TLDR` base class or
  individual test classesJust set it

### Running TLDR with Rake

TLDR ships with a [very](lib/tldr/rake.rb) minimal rake task that simply shells
out to the `tldr` CLI. If you want to run TLDR with Rake, you can configure
the test run by setting flags on an env var named `TLDR_OPTS` or else in
the [.tldr.yml](#setting-defaults-in-tldryml).

Here's an example Rakefile:

```ruby
require "standard/rake"
require "tldr/rake"

task default: [:tldr, "standard:fix"]
```

You could then run the task with:

```
$ TLDR_OPTS="--no-parallel" bundle exec rake tldr
```

One reason you'd want to invoke TLDR with Rake is because you have multiple
test suites that you want to be able to conveniently run separately ([this
talk](https://blog.testdouble.com/talks/2014-05-25-breaking-up-with-your-test-suite/)
discussed a few reasons why this can be useful).

To create a custom TLDR Rake test, just instantiate `TLDR::Task` like this:

```ruby
require "tldr/rake"

TLDR::Task.new(name: :safe_tests, config: TLDR::Config.new(
  paths: FileList["safe/**/*_test.rb"],
  helper: "safe/helper.rb",
  load_paths: ["lib", "safe"]
))
```

The above will create a second Rake task named `safe_tests` running a different
set of tests than the default `tldr` task. Here's [an
example](/example/b/Rakefile).

### Running tests without the CLI

If you'd rather use TLDR by running Ruby files instead of the `tldr` CLI
(similar to `require "minitest/autorun"`), here's how to do it!

Given a file `test/some_test.rb`:

```ruby
require "tldr"
TLDR::Run.at_exit! TLDR::Config.new(no_emoji: true)

class SomeTest < TLDR
  def test_truth
    assert true
  end
end
```

You could run the test with:

```
$ ruby test/some_test.rb
```

To maximize control and to avoid running code accidentally (and _unlike_ the
`tldr` CLI), running `at_exit!` will not set default values to the `paths`,
`helper`, `load_paths`, and `prepend_paths` config properties. You'll have to
pass any values you want to set on a [Config object](/lib/tldr/value/config.rb)
and pass it to `at_exit!`.

To avoid running multiple suites accidentally, if `TLDR::Run.at_exit!` is
encountered multiple times, only the first hook will be registered. If the
`tldr` CLI is running and encounters a call to `at_exit!`, it will be ignored.

#### Setting up the load path

When running TLDR from a Ruby script, one thing the framework can't help you with
is setting up load paths for you.

If you want to require code in `test/` or `lib/` without using
`require_relative`, you'll need to add those directories to the load path. You
can do this programmatically by prepending the path to `$LOAD_PATH`, like
this:

```ruby
$LOAD_PATH.unshift "test"

require "tldr"
TLDR::Run.at_exit! TLDR::Config.new(no_emoji: true)

require "helper"
```

Or by using Ruby's `-I` flag to include it:

```
$ ruby -Itest test/some_test.rb
```

## Questions you might be asking

TLDR is very similar to Minitest in API, but different in enough ways that you
probably have some questions.

### Parallel-by-default is nice in theory but half my tests are failing. Wat?

**Read this before you add `--no-parallel` because some tests are failing when
you run `tldr`.**

The vast majority of test suites in the wild are not parallelized and the vast
majority of _those_ will only parallelize by forking processes as opposed to
using a thread pool. We wanted to encourage more people to save time (after all,
you only get 1.8 seconds here) by making your test suite run as fast as it can,
so your tests run in parallel threads by default.

If you're writing new code and tests with TLDR and dutifully running `tldr`
constantly for fast feedback, odds are that this will help you catch thread
safety issues early—this is a good thing, because it gives you a chance to
address them before they're too hard to fix! But maybe you're porting an
existing test suite to TLDR and running in parallel for the first time, or maybe
you need to test something that simply _can't_ be exercised in a thread-safe
way. For those cases, TLDR's goal is to give you some tools to prevent you from
giving up and adding `--no-parallel` to your entire test suite and **slowing
everything down for the sake of a few tests**.

So, when you see a test that is failing when run in parallel with the rest of your
suite, here is what we recommend doing, in priority order:

1. Figure out a way to redesign the test (or the code under test) to be
thread-safe.  Modern versions of Ruby provide a number of tools to make this
easier than it used to be, and it may be as simple as making an instance
variable thread-local
2. If the problem is that a subset of your tests depend on the same resource,
try using [TLDR.run_these_together!](lib/tldr/parallel_controls.rb) class to
group the tests together. This will ensure that those tests run in the same
thread in sequence (here's a [simple
example](/tests/fixture/run_these_together.rb))
3. For tests that affect process-wide resources like setting the system clock or
changing the process's working directory (i.e. `Dir.chdir`), you can sequester
them to run sequentially _after_ all parallel tests in your suite have run with
[TLDR.dont_run_these_in_parallel!](lib/tldr/parallel_controls.rb), which takes
the same arguments as `run_these_together!`
([example](/tests/fixture/dont_run_these_in_parallel.rb))
4. Give up and make the whole suite `--no-parallel`. If you find that you need
to resort to this, you might save some keystrokes by adding `parallel: false` in
a [.tldr.yml](#setting-defaults-in-tldryml) file

We have a couple other ideas of ways to incorporate non-thread-safe tests into
your suite without slowing down the rest of your tests, so stay tuned!

### How will I run all my tests in CI without the time bomb going off?

TLDR will run all your tests in CI without the time bomb going off. If
`tldr` is run in a non-interactive shell and a `CI` environment variable is set
(as it is on virtually every CI service), then the bomb will be defused.

### Is there a plugin system?

There is not.

Currently, the only pluggable aspect of TLDR are reporters, which can be set
with the `--reporter` command line option. It can be set to any fully-qualified
class name that extends from
[TLDR::Reporters::Base](/lib/tldr/reporters/base.rb).

### What about mocking?

TLDR is laser-focused on running tests, so it doesn't provide a built-in mocking
facility. Might we interest you in a refreshing
[mocktail](https://github.com/testdouble/mocktail), instead?

## Acknowledgements

Thanks to [George Sheppard](https://github.com/fuzzmonkey) for freeing up the
[tldr gem name](https://rubygems.org/gems/tldr)!
