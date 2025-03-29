require "optparse"

class TLDR
  class YamlParser
    def parse path
      require "yaml"
      YAML.load_file(path)
        .transform_keys { |k| k.to_sym }
        .tap do |dotfile_args|
          # Since we don't have shell expansion, we have to glob any paths ourselves
          if dotfile_args.key?(:paths)
            dotfile_args[:paths] = dotfile_args[:paths].flat_map { |path| Dir[path] }
          end
          # The argv parser normally does this:
          if dotfile_args.key?(:reporter)
            begin
              dotfile_args[:reporter] = Kernel.const_get(dotfile_args[:reporter])
            rescue
              raise Error, "Unknown reporter '#{dotfile_args[:reporter]}' specified in #{File.basename(path)} file"
            end
          end
          if dotfile_args.key?(:timeout)
            dotfile_args[:timeout] = case dotfile_args[:timeout]
            when true then Config::DEFAULT_TIMEOUT
            when false then -1
            when String then Float(dotfile_args[:timeout])
            else dotfile_args[:timeout]
            end
          end

          if (invalid_args = dotfile_args.except(*CONFIG_ATTRIBUTES)).any?
            raise Error, "Invalid keys in #{File.basename(path)} file: #{invalid_args.keys.join(", ")}"
          end
        end
    end
  end
end
