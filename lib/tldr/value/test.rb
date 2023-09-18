class TLDR
  Test = Struct.new :klass, :method, :file, :line do
    attr_reader :location

    def initialize(*args)
      super
      @location = Location.new(file, line)
    end
  end
end
