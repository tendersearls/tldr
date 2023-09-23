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
          filter_by_line(
            filter_by_name(tests, config.names),
            search_locations
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
          file, line = subklass.instance_method(method).source_location
          Test.new subklass, method, file, line
        }
      }
    end

    def prepend tests, config
      return tests if config.no_prepend
      prepended_locations = expand_search_locations(config.prepend_tests)
      prepended, rest = tests.partition { |test|
        prepended_locations.any? { |prepend|
          prepend.file == test.file && (prepend.line.nil? || test.covers_line?(prepend.line))
        }
      }
      prepended + rest
    end

    def shuffle tests, seed
      tests.shuffle(random: Random.new(seed))
    end

    def filter_by_line tests, search_locations
      line_specific_locations = search_locations.reject { |location| location.line.nil? }
      return tests if line_specific_locations.empty?

      tests.select { |test|
        line_specific_locations.any? { |location|
          location.file == test.file && test.covers_line?(location.line)
        }
      }
    end

    def filter_by_name tests, names
      return tests if names.empty?

      name_filters = names.map { |name|
        if name.is_a?(String) && name =~ /^\/(.*)\/$/
          Regexp.new $1
        else
          name
        end
      }

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
      return if config.skip_test_helper || !File.exist?(config.helper)
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
  end
end
