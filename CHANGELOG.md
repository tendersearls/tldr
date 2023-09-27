## [Unreleased]

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
