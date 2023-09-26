## [Unreleased]

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
