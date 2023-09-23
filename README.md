# TLDR - a test framework that doesn't have time for slow tests

**tl;dr, this is a very nice test runner for Ruby that fails after 1.8 seconds**

We initially meant this as a joke [while
pairin'](https://www.youtube.com/live/bmi-SWeH4MA?si=p5g1j1FQZrbYEOCg&t=63), but
in addition to being funny, it was also a pretty good idea. So we fleshed out
`tldr` to be a full-featured, mostly
[Minitest-compatible](#minitest-compatibility), and downright pleasant test
framework for Ruby.

Some stuff you might like:

* A CLI that can run tests by line number(s) (e.g. `foo.rb:5 bar.rb:3:10`) and
by names or patterns (e.g. `--name test_fail,test_error --name "/_\d/"`)
* Everything is **parallel by default**, with as many workers as processor cores
on your machine (set with `--workers 42`)
* Surprisingly delightful color diff output when two things fail to equal one another, care of [@mcmire's super_diff gem](https://github.com/mcmire/super_diff)
* By default, the CLI will prepend your most-recently-edited test file to the
front of your suite so its tests will run first. The tests you're working on are
the most likely you care about running, so TLDR runs them first (see the
`--prepend` option)
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
`_test`. They can define `setup` and/or `teardown` methods which will run before
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

(The above will translate to this array of name fiilters internally:
 `["FooTest#test_foo", "test_bar", "test_baz", "/_qux/"]`.)

### Options

Here is the full list of CLI options:

```
$ tldr --help
Usage: tldr [options] some_tests/**/*.rb some/path.rb:13 ...
        --fail-fast                  Stop running tests as soon as one fails
    -s, --seed SEED                  Seed for randomization
        --workers WORKERS            Number of parallel workers (Default: your processor count (24); 1 if a seed is set)
    -n, --name PATTERN               One or more names or /patterns/ of tests to run (like: foo_test, /test_foo.*/, Foo#foo_test)
        --exclude-name PATTERN       One or more names or /patterns/ NOT to run
        --exclude-path PATH          One or more paths NOT to run (like: foo.rb, "test/bar/**", baz.rb:3)
        --helper HELPER              Path to a test helper to load before any tests (Default: "test/helper.rb")
        --no-helper                  Don't try loading a test helper before the tests
        --prepend PATH               Prepend one or more paths to run before the rest (Default: most recently modified test)
        --no-prepend                 Don't prepend any tests before the rest of the suite
    -l, --load-path PATH             Add one or more paths to the $LOAD_PATH (Default: ["test"])
    -r, --reporter REPORTER          Custom reporter class (Default: "TLDR::Reporters::Default")
        --no-emoji                   Disable emoji in the output
    -v, --verbose                    Print stack traces for errors
        --comment COMMENT            No-op comment, used internally for multi-line execution instructions
```

### Minitest compatibility

Tests you write with tldr are designed to be mostly-compatible with
[Minitest](https://github.com/minitest/minitest) tests. Some notes:

* `setup` and `teardown` hook methods should work as you expect
* All of Minitest's assertions (e.g. `assert`, `assert_equals`) are provided,
with these caveats:
  * To retain the `expected, actual` argument ordering, `tldr` defines
  `assert_include?(element, container)` instead of
  `assert_includes(container, element)`
  * If you want to maximize compatibility and mix in `assert_includes` and the
  deprecated `assert_send`, just `include
  TLDR::Assertions::MinitestCompatibility` into the `TLDR` base class or
  individual test classes
G
## Acknowledgements

Thanks to [George Sheppard](https://github.com/fuzzmonkey) for freeing up the
[tldr gem name](https://rubygems.org/gems/tldr)!
