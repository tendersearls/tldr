class TLDR
  Location = Struct.new :file, :line do
    def relative
      if file.start_with?(Dir.pwd)
        file[Dir.pwd.length + 1..]
      else
        file
      end
    end

    def locator
      "#{relative}:#{line}"
    end
  end
end
