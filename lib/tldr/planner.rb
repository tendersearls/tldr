require "pathname"

class TLDR
  class Planner
    def initialize
      @strategizer = Strategizer.new
    end

    def plan config
      $VERBOSE = config.warnings
      search_locations = PathUtil.expand_paths(config.paths, globs: false)

      prepend_load_paths(config)
      require_test_helper(config)
      require_tests(search_locations)

      tests = gather_tests
      config.update_after_gathering_tests!(tests)
      tests_to_run = prepend(
        shuffle(
          exclude_by_path(
            exclude_by_name(
              filter_by_line(
                filter_by_name(tests, config.names),
                search_locations
              ),
              config.exclude_names
            ),
            config.exclude_paths
          ),
          config.seed
        ),
        config
      )

      strategy = @strategizer.strategize(
        tests_to_run,
        GROUPED_TESTS,
        THREAD_UNSAFE_TESTS,
        config
      )

      Plan.new(tests_to_run, strategy)
    end

    private

    def gather_tests
      ClassUtil.gather_descendants(TLDR).flat_map { |subklass|
        ClassUtil.gather_tests(subklass)
      }
    end

    def prepend tests, config
      return tests if config.no_prepend
      prepended_locations = PathUtil.expand_paths(config.prepend_paths)
      prepended, rest = tests.partition { |test|
        PathUtil.locations_include_test?(prepended_locations, test)
      }
      prepended + rest
    end

    def shuffle tests, seed
      tests.shuffle(random: Random.new(seed))
    end

    def exclude_by_path tests, exclude_paths
      excluded_locations = PathUtil.expand_paths(exclude_paths)
      return tests if excluded_locations.empty?

      tests.reject { |test|
        PathUtil.locations_include_test?(excluded_locations, test)
      }
    end

    def exclude_by_name tests, exclude_names
      return tests if exclude_names.empty?

      name_excludes = expand_names_with_patterns(exclude_names)

      tests.reject { |test|
        name_excludes.any? { |filter|
          filter === test.method_name.to_s || filter === "#{test.test_class}##{test.method_name}"
        }
      }
    end

    def filter_by_line tests, search_locations
      line_specific_locations = search_locations.reject { |location| location.line.nil? }
      return tests if line_specific_locations.empty?

      tests.select { |test|
        PathUtil.locations_include_test?(line_specific_locations, test)
      }
    end

    def filter_by_name tests, names
      return tests if names.empty?

      name_filters = expand_names_with_patterns(names)

      tests.select { |test|
        name_filters.any? { |filter|
          filter === test.method_name.to_s || filter === "#{test.test_class}##{test.method_name}"
        }
      }
    end

    def prepend_load_paths config
      config.load_paths.each do |load_path|
        $LOAD_PATH.unshift(File.expand_path(load_path, Dir.pwd))
      end
    end

    def require_test_helper config
      return if config.no_helper || config.helper_paths.empty?
      PathUtil.expand_paths(config.helper_paths).map(&:file).uniq.each do |helper_file|
        next unless File.exist?(helper_file)

        require helper_file
      end
    end

    def require_tests search_locations
      search_locations.each do |location|
        require location.file
      end
    end

    def expand_names_with_patterns names
      names.map { |name|
        if name.is_a?(String) && name =~ /^\/(.*)\/$/
          Regexp.new($1)
        else
          name
        end
      }
    end
  end
end
