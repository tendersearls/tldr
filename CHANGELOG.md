## unreleased

## [1.1.0]

* Add `--exit-0-on-timeout` to allow the suite timeout to be used more as a budget constraint (e.g. "I know my full suite is going to take 30 seconds to run but I want to constantly run as many as I can in 500ms to get fast feedback")
* Add `--exit-2-on-failure` flag to exit with status 2 for test failures (not just errors), useful for Claude Code hooks which only block on exit code 2

## [1.0.0]

* **BREAKING** you know how the whole point of TLDR is that it aborts your test
run after 1.8s? Yeah, well, it doesn't anymore. Use `--timeout` to enable it
* **BREAKING** replace the `--no-dotfile` flag and has been replaced by a
`--[no-]config PATH` flag. To skip loading the YAML file, use `--no-config`.
To set the file, use `--config FILE` option
* **BREAKING** Remove `assert_include?` and `refute_include?` in favor of
Minitest-compatible `assert_includes` and `refute_includes`.
* **BREAKING** Rename `TLDR::Assertions::MinitestCompatibility` to `TLDR::MinitestCompatibility` and remove `assert_send`, which [nobody uses](https://github.com/minitest/minitest/issues/668)
* **BREAKING** Replace `no_emoji` YAML option with `emoji` option. Disable emoji output by default. Add `--emoji` flag for enabling it.
* Add `--[no-]timeout TIMEOUT` flag and `timeout` YAML option. To enable the
TLDR Classic™ default of 1.8s, specify `--timeout` from the CLI or `timeout: true`
in YAML. To specify a custom timeout of 42.3 seconds, flag `--timeout 42.3` or
`timeout: 42.3` in YAML
* Add `require "tldr/autorun"`, which adds an `at_exit` hook so that tests can be
run from the command line (still supports CLI args and YAML options) by running `ruby path/to/test.rb` (see [its test](/tests/autorun_test.rb))
* Fix custom reporters by looking them up only after helpers have a chance to run. [#15](https://github.com/tendersearls/tldr/issues/15)

## [0.10.1]

* Fix 3.4 / Prism [#17](https://github.com/tendersearls/tldr/pull/17)

## [0.10.0]

* Add an option to print the stack traces of interrupted tests [#13](https://github.com/tendersearls/tldr/pull/13) by [@henrahmagix](https://github.com/henrahmagix)

## [0.9.5]

* Fix warning when defining `setup`/`teardown` on TLDR class itself [#7](https://github.com/tendersearls/tldr/issues/7)

## [0.9.4]

* Fix Sorbet compatibility [#5](https://github.com/tendersearls/tldr/issues/5)

## [0.9.3]

* Print how many tests ran vs. didn't even when suppressing TLDR summary

## [0.9.2]

* Don't redundantly print out dotfile config values for re-run instructions

## [0.9.1]

* Correctly clear the screen between runs

## [0.9.0]

* Add a `--watch` option that will spawn fswatch | xargs and clear the screen
between runs (requires fswatch to gbe installed)
* Add "lib" as a default load path along with "test"

## [0.8.0]

* Add a `--yes-i-know` flag that will suppress the large warning when your test
suite runs over the 1.8s limit

## [0.7.0]

* Add a `tldt` alias for folks who have another executable named `tldr` on their
paths
* BREAKING: Reverse decision in 0.1.1 to capture_io on every TLDR subclass;
moving back to the MinitestCompatibility mixin
* Fix `assert_in_delta` defaultarg to retain Minitest compatibility
* Add `mu_pp` to the MinitestCompatibility mixin

## [0.6.2]

* Since TLDR runs fine on 3.1, reduce the gem requirement

## [0.6.1]

* Correctly report the number of test classes that run
* Finish planning the test run before starting the clock on the timer (that's
a millisecond or two in savings!)

## [0.6.0]

* When `dont_run_these_in_parallel!` and `run_these_together!` are called from a
super class, gather subclasses' methods as well when the method is `nil`
* Stop shelling out to `tldr` from our Rake task. Rescue `SystemExit` instead
* Rename `Config#helper` to `Config#helper_paths`, which YAML config keys
* Print Ruby warnings by default (disable with --no-warnings)

## [0.5.0]

* Define your own Rake tasks with `TLDR::Task` and pass in a custom configuration
* Any tests with `--prepend` AND marked thread-unsafe with `dont_run_these_in_parallel`
will be run BEFORE the parallel tests start running. This way if you're working
on a non-parallelizable test, running `tldr` will automatically run it first
thing
* Stop printing `--seed` in run commands, since it can be confusing to discover
that will disable `--parallel`. Instead, print the seed option beneath

## [0.4.0]

* Add `TLDR.dont_run_these_in_parallel!` method to allow tests to indicate that they
must be run in isolation and not concurrently with any other tests
* Add support for `around` hooks (similar to [minitest-around](https://github.com/splattael/minitest-around))

## [0.3.0]

* Add `TLDR.run_these_together!` method to allow tests that can't safely be run
concurrently to be grouped and run together

## [0.2.1]

* Define a default empty setup/teardown in the base class, to guard against
users getting `super: no superclass method `setup'` errors when they dutifully
call super from their hooks

## [0.2.0]

- Add a rake task "tldr"
## [0.1.1]

- Improve Minitest compatibility by mixing in Assertions#capture_io
- Fix whitespace in reporter

## [0.1.0]

- Initial release
