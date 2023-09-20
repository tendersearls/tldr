class TLDR
  Location = Struct.new :file, :line do
    def relative
      file_path = Pathname.new(file)
      if file_path.absolute?
        file_path.relative_path_from(Pathname.new(Dir.pwd))
      else
        file_path
      end
    end

    def locator
      "#{relative}:#{line}"
    end
  end
end
