## unreleased

* **BREAKING** change the `--no-dotfile` flag and has been replaced by a
`--[no-]config PATH` flag. To skip loading the YAML file, use `--no-config`.
To set the file, use `--config FILE` option

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
