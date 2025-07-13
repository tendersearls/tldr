# TLDR - Testing for rubyists who want fast feedback

TLDR is a suspiciously-delightful testing framework for Ruby.

As a test library, TLDR is largely [API-compatible with Minitest](#minitest-compatibility). As a test runner, TLDR boasts a few features RSpec's CLI still doesn't have.

The library, command line interface, and every decision in-between was prioritized to maximize productivity to promote fast feedback loops. Some highlights:

* Numerous ways to run specific tests: path (`foo_test.rb`), line number (`foo_test.rb:13`), name (`--name test_foo`), or regex pattern (`-n /_foo/`)
* Parallel test execution by default, as well as [controls for serial execution of thread-unsafe tests](#parallel-by-default-is-nice-in-theory-but-half-my-tests-are-failing-wat)
* Continuously run [after every file change](#running-tests-continuously-with---watch) with `--watch`
* An optional timer to [enforce your tests never get slow](#enforcing-a-testing---timeout) with `--timeout`
* A `--fail-fast` flag that aborts the run [as soon as a failure is encountered](#failing-fast-and-first)
* Running your most-recently-edited test before all the others (see `--prepend`)
* Delightful diffs when assertions fail, care of [super_diff](https://github.com/splitwise/super_diff)

We hope you'll give it a try!

## Getting started

You can either read the rest of this README and learn about TLDR passively, or you can just clone this [TLDR demo repo](https://github.com/searls/tldr_demo) and work through its README as you play with its tests and run them with various options.

**JUST IN CASE YOU'RE ALREADY SKIMMING THIS**, I said stop reading and [clone this interactive repo](https://github.com/searls/tldr_demo) if you're a hands-on learner.

### Install

You know the drill. `gem install tldr` or add it to your Gemfile:

```
gem "tldr"
```

### Project setup

By default, TLDR expects your tests to be in `test/` with filenames that match `test_*.rb` or `*_test.rb` and will require a `test/helper.rb` if you define one.

## Configuring TLDR

### CLI Options

```
$ tldr --help
Usage: tldr [options] some_tests/**/*.rb some/path.rb:13 ...
    -t, --[no-]timeout [TIMEOUT]     Timeout (in seconds) before timer aborts the run (Default: 1.8)
        --watch                      Run your tests continuously on file save (requires 'fswatch' to be installed)
        --fail-fast                  Stop running tests as soon as one fails
        --[no-]parallel              Parallelize tests (Default: true)
    -s, --seed SEED                  Random seed for test order (setting --seed disables parallelization by default)
    -n, --name PATTERN               One or more names or /patterns/ of tests to run (like: foo_test, /test_foo.*/, Foo#foo_test)
        --exclude-name PATTERN       One or more names or /patterns/ NOT to run
        --exclude-path PATH          One or more paths NOT to run (like: foo.rb, "test/bar/**", baz.rb:3)
        --helper PATH                One or more paths to a helper that is required before any tests (Default: "test/helper.rb")
        --no-helper                  Don't require any test helpers
        --prepend PATH               Prepend one or more paths to run before the rest (Default: most recently modified test)
        --no-prepend                 Don't prepend any tests before the rest of the suite
    -l, --load-path PATH             Add one or more paths to the $LOAD_PATH (Default: ["lib", "test"])
        --base-path PATH             Change the working directory for all relative paths (Default: current working directory)
    -c, --[no-]config PATH           The YAML configuration file to load (Default: '.tldr.yml')
    -r, --reporter REPORTER          Set a custom reporter class (Default: "TLDR::Reporters::Default")
        --[no-]emoji                 Enable emoji output for the default reporter (Default: false)
        --[no-]warnings              Print Ruby warnings (Default: true)
    -v, --verbose                    Print stack traces for errors
        --yes-i-know                 Suppress TLDR report when suite runs beyond any configured --timeout
        --exit-0-on-timeout          Exit with status code 0 when suite times out instead of 3
        --exit-2-on-failure          Exit with status code 2 (normally for errors) for both failures and errors
        --print-interrupted-test-backtraces
                                     Print stack traces of tests interrupted after a timeout
```

### Setting defaults in .tldr.yml

The `tldr` CLI will look for a `.tldr.yml` file in the root of your project that can set all the same options supported by the CLI. You can specify a custom YAML location with `--config some/path.yml` if you want it to live someplace else.

Any options found in the dotfile will override TLDR's defaults, but can still be overridden by the `tldr` CLI or a `TLDR::Config` object when running tests programmatically.

Here's an [example project](/example/c) that specifies a `.tldr.yml` file as well as some [internal tests](/tests/dotfile_test.rb) demonstrating its behavior.

## Writing your tests

If you've ever seen a [Minitest](https://github.com/minitest/minitest?tab=readme-ov-file#synopsis-) test, then you already know how to write TLDR tests. Rather than document how to write tests, this section just highlights the ways TLDR tests differ from Minitest tests.

First, instead of inheriting from `Minitest::Test`, TLDR test classes should descend from (wait for it) the `TLDR` base class:

```ruby
class MyTest < TLDR
  def test_looks_familiar
    assert true
  end
end
```

Second, if your tests depend on a test helper, it will be automatically loaded by TLDR _if_ you name it `test/helper.rb`. That means you don't need to add `require "helper"` to the top of every test. If you want to name the helper something else, you can do so with the `--helper` option:

```
tldr --helper test/test_helper.rb
```

Third, TLDR offers fewer features:

* No built-in mock library ([use mocktail](https://justin.searls.co/posts/a-real-world-mocktail-example-test/), maybe!)
* No "spec" API
* No benchmark tool
* No bisect script

And that's it! You officially know how to write TLDR tests.

## Running your tests

Because TLDR ships with a CLI, it offers a veritable _plethora_ of ways to run your tests.

### Running your tests

Once installed, running all your tests is just five keystrokes away:

```
tldr
```

This assumes your tests are stored in `test/`. It will also add `lib/` to Ruby's load paths and require `test/helper.rb` before your tests, if it exists.

### Running TLDR with Rake

TLDR ships with a minimal [rake task](lib/tldr/rake.rb) that simply shells out to the `tldr` CLI by default. If you want to run TLDR with Rake, you can configure the task by setting flags on an env var named `TLDR_OPTS` or in a [.tldr.yml file](#setting-defaults-in-tldryml).

All your Rakefile needs is `require "tldr/rake"` and you can run the task individually like this:

```
$ rake tldr

# Or, with options in TLDR_OPTS
$ TLDR_OPTS="--no-parallel" rake tldr
```

Here's an example Rakefile that runs both TLDR and [Standard Ruby](https://github.com/standardrb/standard) as the default task:

```ruby
require "standard/rake"
require "tldr/rake"

task default: ["tldr", "standard:fix"]
```

One situation where you'd want to invoke TLDR with Rake is when you have multiple test suites that you want to be able to easily run separately ([this talk](https://blog.testdouble.com/talks/2014-05-25-breaking-up-with-your-test-suite/) discussed a few reasons why this can be useful).

To create a custom TLDR Rake task, you can instantiate `TLDR::Task` like this, which allows you to define its [TLDR::Config](/lib/tldr/value/config.rb) configuration in code:

```ruby
require "tldr/rake"

TLDR::Task.new(name: :safe_tests, config: TLDR::Config.new(
  paths: FileList["safe/**/*_test.rb"],
  helper_paths: ["safe/helper.rb"],
  load_paths: ["lib", "safe"]
))
```

The above will create a second Rake task named `safe_tests` running a different set of tests than the default `tldr` task. Here's [an example](/example/b/Rakefile) from TLDR's test suite.

### Running tests continuously with --watch

The `tldr` CLI includes a `--watch` option that will watch for changes in any of the configured load paths (`["test", "lib"]` by default) and then execute your tests each time a file is changed. To keep the output up-to-date and easy
to scan, it will also clear your console before each run.

Note that this feature requires you have [fswatch](https://github.com/emcrisostomo/fswatch) installed and on your `PATH`

Here's what that might look like with the `--emoji` flag enabled:

![tldr-watch](https://github.com/tendersearls/tldr/assets/79303/364f0e52-5596-49ce-a470-5eaeddd11f03)

### Running tests programmatically

If you'd rather use TLDR by running Ruby files instead of the `tldr` CLI, you can simply `require "tldr/autorun"` (just like `require "minitest/autorun"`).

Given a file `test/some_test.rb`:

```ruby
require "tldr/autorun"

class SomeTest < TLDR
  def test_truth
    assert true
  end
end
```

You can then run the test by passing `ruby` the file:

```
$ ruby test/some_test.rb
```

Any CLI options you add will still be parsed, as well (e.g. `ruby my_test.rb --emoji` will work).

If you want to be explicit about setting the `Kernel.at_exit` hook, or if you want to configure TLDR with code, you can invoke `TLDR.at_exit!` directly:

```ruby
require "tldr"
TLDR::Run.at_exit! TLDR::Config.new(emoji: true)
```

## Failing with style

### Failing fast and first

If we just want to know if the build passes, we want to know as fast as possible. Ever see a test fail and then sit around waiting for the whole suite to finish running anyway? Why wait? Turn on `--fail-fast` and abort the test run the instant a failure is encountered:

```
tldr --fail-fast
```

Additionally, you might notice the top of each run will show you a command you can use to execute the same run, like this:

```
Command: bundle exec tldr --fail-fast --prepend "test/calculator_test.rb"
```

That's because TLDR will look at the file system and move your most-recently-edited test file to the front of the queue with `--prepend`. When used in conjunction with `--fail-fast`, you'll fail _extra fast_, because the most likely test to fail is the one you're actively working on.

### Enforcing a testing --timeout

We initially developed TLDR because we wanted a test runner that supported suite-wide time limits as a first-class feature. When test suites become slow, people run them (_much_) less often. And once a developer gets in the habit of only running tests occasionally,  it's not long before they only run them before push, and then only the ones they're immediately working on, and then they just wait for CI to run them in a pull request. And if you don't run all your tests very often, you don't feel any pain when you make your tests (or the code its testing) slower.

Each time you write code and don't run your tests, you're making an assumption that whatever code you just wrote _works flawlessly_. If that assumption is correct, you saved however much time it takes to run your tests. But every time that assumption is incorrect, you've just extended the amount of time before discovering that you broke something. If that's a few minutes later, that might only cost a few minutes of rework. **If you only run tests once or twice a day, you might have to undo hours of work to fix it.**

We originally came up with the idea of TLDR [on a livestream](https://www.youtube.com/live/bmi-SWeH4MA?si=p5g1j1FQZrbYEOCg&t=63), joking that only an unconfigurable 1.8 second time limit would prevent test suites from ballooning in duration over time. As of 1.0, we've made the timeout configurable, but we still think it's a good idea to enable it with the `--timeout` option:

```
tldr --timeout
```

Not only does a timeout keep us running the whole suite frequently (it'll never take more than 1.8 seconds, after all), but even if the suite begins to exceed our self-imposed timeout, TLDR's random test order and parallel execution means that—so long as you keep running that partial suite frequently—you'll still be running ALL your tests _many more times_ than if they waited until some arbitrary checkpoint to run them.

When enabled, `--timeout` will set the timer to 1.8 seconds. But you can set whatever time limit you like. The right value is depends on your individual capacity for paying attention. Basically, "however long you're willing to wait without caving and running your tests less often."

Examples:

```
# A badass 200ms timeout
tldr --timeout 0.2

# A miserable-sounding 20 second timeout
tldr --timeout 20
```

If we've won you over towards this way of working, we suggest creating a [.tldr.yml file](#setting-defaults-in-tldryml) in the root of your project and specifying your desired timeout.

For TLDR Classic™ and a 1.8s timeout:

```yaml
# .tldr.yml
timeout: true
```

Or any number of seconds you like:

```yaml
# .tldr.yml
timeout: 0.01
```

And if you're running with the timeout enabled this way, you can still disable it for any given test run by adding the `--no-timeout` flag.

#### Consider timeouts as a success with exit code 0

By default, when TLDR times out it exits with status code 3 to indicate the test suite was aborted. However, if you know that your full test suite is slower than whatever duration you consider to be "fast enough for fast feedback", you can use the `--exit-0-on-timeout` flag and simply use the timeout to enforce whatever feedback loop budget you set with `--timeout`.

For example:

```
# Get feedback within 400ms but don't consider a timeout a failure
tldr --timeout 0.4 --exit-0-on-timeout
```

This is particularly useful for:
- [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) where you want fast feedback without failing the command
- [Git pre-commit hooks](https://git-scm.com/docs/githooks#_pre_commit) where you want quick test results without blocking commits
- Development workflows where timeouts are informational rather than failures
- Any situation where you want a time budget without hard failures

## Using TLDR as a Claude Code hook

In AI agent-based coding workflows, it's common to [configure hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) that will block the agent from proceeding whenever tests or linters fail. With Claude Code specifically, a hook will only block if it exits with status code 2. As a result, you can use `--exit-2-on-failure` so that assertion failures will block the agent from continuing.

So you might configure a Claude Code hook with a 250ms budget by setting timeouts to exit code 0 and failures to exit code 2:

```
# Get feedback within 250ms, don't block the agent on timeouts, but do block it on assertion failures
tldr --timeout 0.25 --exit-0-on-timeout --exit-2-on-failure
```


## Questions you might be asking

TLDR is very similar to Minitest in API, but different in enough ways that you
probably have some questions.

## Wait, isn't this the one that blows up after 1.8 seconds?

The `tldr` gem was initially developed and released after we did a [lighthearted pairing session]() and imagined a Ruby test runner with a CLI and an unorthodox, unconfigurable rule: a hard-and-fast 1.8 second time limit on every test suite.

In the 18 months since, and to our utter surprise, TLDR did not immediately rise to the top of the charts and dominate the Ruby testing world.

While we still contend the mandatory time limit was a Very Good Idea (even if your tests are necessarily slower than 1.8 seconds), we believe there is a very remote, almost certainly wrong possibility that it was slowing adoption of this otherwise very capable test runner. As a result, **as of 1.0.0, the 1.8s timeout is disabled by default, and can be re-enabled (and even set to a specific value) with the `--timeout` option.

### Minitest compatibility

Tests you write with tldr are designed to be mostly-compatible with [Minitest](https://github.com/minitest/minitest) tests.

Details:

* We [implemented all](/lib/tldr/assertions.rb) of Minitest's built-in assertions (e.g. `assert`, `assert_equals`)
* `setup` and `teardown` hook methods should work as you expect. (We even threw in [our own `around` hook](https://github.com/search?q=repo%3Atendersearls/tldr%20%3Aaround&type=code), free of charge!)
* If you need anything else from Minitest as you port tests to TLDR, try `include TLDR::MinitestCompatibility`, and if that doesn't do the trick [add whatever you need in a pull request](/lib/tldr/minitest_compatibility.rb)

### Parallel-by-default is nice in theory but half my tests are failing. Wat?

**Read this before you add `--no-parallel` because some tests are failing when you run `tldr`.**

The vast majority of test suites in the wild are run sequentially even though they'd work perfectly fine in parallel. Why? Because test runners tend not to enable it by default. Moreover, when they do, they usually rely on forking processes, which is slower and more resource-intensive than using threads or [Ractors](https://docs.ruby-lang.org/en/3.4/ractor_md.html). For this reason, TLDR is optimistic by default and will multi-thread your test suite.

So, what do you do when you run into a situation where a test has good reason not to run in parallel? Either because of resource contention or because the order of its test cases actually matters? Here's what we'd do:

1. Start by challenging the assumption that the test can't be run in a thread-safe way (it may be as simple as changing a globally-edited instance variable to a [thread-local](https://docs.ruby-lang.org/en/master/Thread.html#class-Thread-label-Fiber-local+vs.+Thread-local))
2. If the problem is that a subset of your tests depend on the same resource, try using [TLDR.run_these_together!](/lib/tldr/parallel_controls.rb) class to group the tests together. This will ensure that those tests run in the same thread in sequence (here's a [simple example](/tests/fixture/run_these_together.rb))
3. For tests that affect process-wide resources like setting the system clock or changing the process's working directory (i.e. `Dir.chdir`), you can sequester them to run sequentially _after_ all parallel tests in your suite have run with [TLDR.dont_run_these_in_parallel!](lib/tldr/parallel_controls.rb), which takes the same arguments as `run_these_together!` ([example](/tests/fixture/dont_run_these_in_parallel.rb))
4. Give up and make the whole suite `--no-parallel`. If you find that you need to resort to this, you might save some keystrokes by adding `parallel: false` in a [.tldr.yml](#setting-defaults-in-tldryml) file

### Any help porting from Minitest?

If you're currently using Minitest, you can take a stab at dropping your dependency on the minitest gem and replace references to `Minitest::Test` dynamically in a test helper, like I did for my [todo_or_die gem](https://github.com/searls/todo_or_die/blob/b50beb0166307d901393435594508f5142976c93/test/helper.rb#L7-L16):

```
require "tldr"
if defined?(Minitest::Test)
  TLDR::MinitestTestBackup = Minitest::Test
  Minitest.send(:remove_const, "Test")
end
module Minitest
  class Test < TLDR
    include TLDR::MinitestCompatibility
  end
end
```

This probably won't work for complex projects, but it might for simple ones!

### Is there a plugin system?

There is not.

Currently, the only pluggable aspect of TLDR are reporters, which can be set
with the `--reporter` command line option. It can be set to any fully-qualified
class name that responds to the same methods defined in
[TLDR::Reporters::Base](/lib/tldr/reporters/base.rb).

If you define a custom reporter, be sure to require it from your test helper, so TLDR can instantiate it!

### What if I already have another `tldr` executable on my path?

There's a [command-line utility named tldr](https://tldr.sh) that might conflict with this gem's executable in your PATH. If that's the case, you could either change your path, invoke `bundle exec tldr`, run [with Rake](#running-tldr-with-rake), or use the `tldt` ("too long; didn't test") executable alias that ships with this gem.

## Contributing to TLDR

If you want to submit PRs on this repo, please know that the code style is
[Kirkland-style Ruby](https://mastodon.social/@searls/111137666157318482), where
method definitions have parentheses omitted but parentheses are generally
expected for method invocations.

## Acknowledgements

Thanks to [George Sheppard](https://github.com/fuzzmonkey) for freeing up the
[tldr gem name](https://rubygems.org/gems/tldr)!
