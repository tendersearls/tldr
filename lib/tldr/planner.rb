require "pathname"

class TLDR
  class Planner
    def plan config
      search_locations = expand_search_locations config.paths

      prepend_load_paths config
      require_test_helper config
      require_tests search_locations

      tests = gather_tests
      config.update_after_gathering_tests! tests

      Plan.new prepend(
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
    end

    private

    def expand_search_locations path_strings
      path_strings.flat_map { |path_string|
        File.directory?(path_string) ? Dir["#{path_string}/**/*.rb"] : path_string
      }.flat_map { |path_string|
        absolute_path = File.expand_path(path_string.gsub(/:.*$/, ""), Dir.pwd)
        line_numbers = path_string.scan(/:(\d+)/).flatten.map(&:to_i)

        if line_numbers.any?
          line_numbers.map { |line_number| Location.new absolute_path, line_number }
        else
          [Location.new(absolute_path, nil)]
        end
      }.uniq
    end

    def gather_tests
      gather_descendants(TLDR).flat_map { |subklass|
        subklass.instance_methods.grep(/^test_/).sort.map { |method|
          file, line = SorbetCompatibility.unwrap_method(subklass.instance_method(method)).source_location
          Test.new subklass, method, file, line
        }
      }
    end

    def prepend tests, config
      return tests if config.no_prepend
      prepended_locations = expand_search_locations expand_globs config.prepend_tests
      prepended, rest = tests.partition { |test|
        locations_include_test? prepended_locations, test
      }
      prepended + rest
    end

    def shuffle tests, seed
      tests.shuffle(random: Random.new(seed))
    end

    def exclude_by_path tests, exclude_paths
      excluded_locations = expand_search_locations expand_globs exclude_paths
      return tests if excluded_locations.empty?

      tests.reject { |test|
        locations_include_test? excluded_locations, test
      }
    end

    def exclude_by_name tests, exclude_names
      return tests if exclude_names.empty?

      name_excludes = expand_names_with_patterns exclude_names

      tests.reject { |test|
        name_excludes.any? { |filter|
          filter === test.method.to_s || filter === "#{test.klass}##{test.method}"
        }
      }
    end

    def filter_by_line tests, search_locations
      line_specific_locations = search_locations.reject { |location| location.line.nil? }
      return tests if line_specific_locations.empty?

      tests.select { |test|
        locations_include_test? line_specific_locations, test
      }
    end

    def filter_by_name tests, names
      return tests if names.empty?

      name_filters = expand_names_with_patterns names

      tests.select { |test|
        name_filters.any? { |filter|
          filter === test.method.to_s || filter === "#{test.klass}##{test.method}"
        }
      }
    end

    def prepend_load_paths config
      config.load_paths.each do |load_path|
        $LOAD_PATH.unshift File.expand_path(load_path, Dir.pwd)
      end
    end

    def require_test_helper config
      return if config.no_helper || config.helper.nil? || !File.exist?(config.helper)
      require File.expand_path(config.helper, Dir.pwd)
    end

    def require_tests search_locations
      search_locations.each do |location|
        require location.file
      end
    end

    def gather_descendants root_klass
      root_klass.subclasses + root_klass.subclasses.flat_map { |subklass|
        gather_descendants subklass
      }
    end

    def locations_include_test? locations, test
      locations.any? { |location|
        location.file == test.file && (location.line.nil? || test.covers_line?(location.line))
      }
    end

    # Because search paths to TLDR can include line numbers (e.g. a.rb:4), we
    # can't just pass everything to Dir.glob. Instead, we have to check whether
    # a user-provided search path looks like a glob, and if so, expand it
    #
    # Globby characters specified here:
    # https://ruby-doc.org/3.2.2/Dir.html#method-c-glob
    def expand_globs search_paths
      search_paths.flat_map { |search_path|
        if search_path.match?(/[*?\[\]{}]/)
          raise Error, "Can't combine globs and line numbers in: #{search_path}" if search_path.match?(/:(\d+)$/)
          Dir[search_path]
        else
          search_path
        end
      }
    end

    def expand_names_with_patterns names
      names.map { |name|
        if name.is_a?(String) && name =~ /^\/(.*)\/$/
          Regexp.new $1
        else
          name
        end
      }
    end
  end
end
