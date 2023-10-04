class TLDR
  module PathUtil
    def self.expand_paths path_strings, globs: true
      path_strings = expand_globs(path_strings) if globs

      path_strings.flat_map { |path_string|
        File.directory?(path_string) ? Dir["#{path_string}/**/*.rb"] : path_string
      }.flat_map { |path_string|
        absolute_path = File.expand_path(path_string.gsub(/:.*$/, ""), Dir.pwd)
        line_numbers = path_string.scan(/:(\d+)/).flatten.map(&:to_i)

        if line_numbers.any?
          line_numbers.map { |line_number| Location.new(absolute_path, line_number) }
        else
          [Location.new(absolute_path, nil)]
        end
      }.uniq
    end

    # Because search paths to TLDR can include line numbers (e.g. a.rb:4), we
    # can't just pass everything to Dir.glob. Instead, we have to check whether
    # a user-provided search path looks like a glob, and if so, expand it
    #
    # Globby characters specified here:
    # https://ruby-doc.org/3.2.2/Dir.html#method-c-glob
    def self.expand_globs search_paths
      search_paths.flat_map { |search_path|
        if search_path.match?(/[*?\[\]{}]/)
          raise Error, "Can't combine globs and line numbers in: #{search_path}" if search_path.match?(/:(\d+)$/)
          Dir[search_path]
        else
          search_path
        end
      }
    end

    def self.locations_include_test? locations, test
      locations.any? { |location|
        location.file == test.file && (location.line.nil? || test.covers_line?(location.line))
      }
    end
  end
end
