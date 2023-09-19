require "pathname"

class TLDR
  class Planner
    def plan config
      require_load_paths config
      require_test_helper config
      require_tests config.paths

      tests = shuffle(
        filter_by_line(
          filter_by_name(gather_tests, config.names),
          config.paths
        ),
        config.seed
      )
      Plan.new(tests).tap do |tests|
        config.reporter.before_suite config, tests
      end
    end

    private

    def require_load_paths config
      config.load_paths.each do |load_path|
        $LOAD_PATH.unshift File.expand_path(load_path, Dir.pwd)
      end
    end

    def require_test_helper config
      return if config.skip_test_helper || !File.exist?(config.helper)
      require File.expand_path(config.helper, Dir.pwd)
    end

    def require_tests paths
      absolute_paths = paths.map { |arg| absolutify_path(arg) }.uniq
      absolute_paths.each do |path|
        require path
      end
    end

    def absolutify_path path
      File.expand_path(path.gsub(/:.*$/, ""), Dir.pwd)
    end

    def gather_tests
      gather_descendants(TLDR).flat_map { |subklass|
        subklass.instance_methods.grep(/^test_/).sort.map { |method|
          file, line = subklass.instance_method(method).source_location
          Test.new subklass, method, file, line
        }
      }
    end

    def gather_descendants root_klass
      root_klass.subclasses + root_klass.subclasses.flat_map { |subklass|
        gather_descendants subklass
      }
    end

    def shuffle tests, seed
      tests.shuffle(random: Random.new(seed))
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

    def filter_by_line tests, paths
      line_filters = parse_line_filters paths
      return tests if line_filters.empty?

      tests.select { |test|
        next if (filtered_lines = line_filters[test.file]).empty?
        test_method = test.klass.instance_method(test.method)
        next if filtered_lines.all? { |line| line < test_method.source_location[1] }

        ast = RubyVM::AbstractSyntaxTree.of(test_method)
        filtered_lines.any? { |line|
          line.between? ast.first_lineno, ast.last_lineno
        }
      }
    end

    def parse_line_filters paths
      filter_patterns = paths.select { |path| path.match?(/:\d+$/) }

      Hash.new { |h, key| h[key] = [] }.tap do |line_filters|
        filter_patterns.flat_map { |pattern|
          file_path = absolutify_path pattern
          line_numbers = pattern.scan(/:(\d+)/).flatten.map(&:to_i)

          line_filters[file_path] = (line_filters[file_path] | line_numbers.map(&:to_i)).sort
        }
      end
    end
  end
end
