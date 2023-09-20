# TLDR

We started this [while
pairin'](https://www.youtube.com/watch?v=bmi-SWeH4MA&t=2) after imagining a test
runner for Ruby that helped make sure people's test suites didn't grow into
really slow distractions by refusing to run suites longer than 1.8 seconds.

## Install

Either `gem install tldr` or add it to your Gemfile:

```
gem "tldr"
```

## Usage

Here's what a test looks like:

```ruby
class MyTest < TLDR
  def test_truth
    assert true
  end
end
```

Stick your tests in `test/**/*_test.rb` (and/or `test/**/test_*.rb`) files
and they'll be found automatically.  Same goes for a `test/helper.rb` file,
which will be loaded prior to your tests by the CLI if it exists.

Then just run the CLI:

```
$ bundle exec tldr
```

You can, of course, also just run a specific test file or glob:

```
$ bundle exec tldr test/this/one/in/particular.rb
```

### Minitest compatibility

Tests you write with tldr are designed to be mostly-compatible with
[Minitest](https://github.com/minitest/minitest) tests. Some notes:

* `setup` and `teardown` hook methods should work as you expect
* All of Minitest's assertions (e.g. `assert`, `assert_equals` are implemented
in tldr, with these caveats:
  * To retain the `expected, actual` argument ordering, `assert_include?(element, container)` is provided instead of `assert_includes(container, element)`
  * If you want to maximize compatibility and mix in `assert_includes` and the
  deprecated `assert_send`, just `include
  TLDR::Assertions::MinitestCompatibility` into your test class

### Running by line numbers

When running the `tldr` CLI command, you can select tests using your shell's
glob expansion, list multiple paths, and even specify one or more line numbers
of tests to run at a given path.

For example, to run only the first and third test in
[line_numbers.rb](/test/fixture/line_number.rb), any line numbers we filter will
select only the tests whose source covers those lines:

```
$ bundle exec tldr test/fixture/line_number.rb:3:10
```

### Options

Here are the CLI options:

```
$ tldr --help
Usage: tldr [options] some_tests/**/*.rb some/path.rb:13 ...
        --fail-fast                  Stop running tests as soon as one fails
        --helper HELPER              Path to a test helper to load before any tests (Default: "test/helper.rb")
    -n, --name PATTERN               One or more names or /pattern/ of tests to run (like: foo_test, /foo_.*/, Foo#foo_test)
    -s, --seed SEED                  Seed for randomization
        --skip-test-helper           Don't try loading a test helper before the tests
    -l, --load-path PATH             Add one or more paths to the $LOAD_PATH (Default: ["test"])
    -r, --reporter REPORTER          Custom reporter class (Default: "TLDR::Reporters::Default")
        --workers WORKERS            Number of parallel workers (Default: 8, the number of CPU cores)
    -v, --verbose                    Print stack traces for errors
```

## Acknowledgements

Thanks to [George Sheppard](https://github.com/fuzzmonkey) for freeing up the
[tldr gem name](https://rubygems.org/gems/tldr)!
