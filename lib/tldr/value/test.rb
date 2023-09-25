class TLDR
  Test = Struct.new :klass, :method, :file, :line do
    attr_reader :location

    def initialize(*args)
      super
      @location = Location.new(file, line)
    end

    # Memoizing at call time, because re-parsing isn't free and isn't usually necessary
    def end_line
      @end_line ||= begin
        test_method = SorbetCompatibility.unwrap_method klass.instance_method(method)
        RubyVM::AbstractSyntaxTree.of(test_method).last_lineno
      end
    end

    # Test exact match starting line condition first to save us a potential re-parsing to look up end_line
    def covers_line? l
      line == l || (l >= line && l <= end_line)
    end
  end
end
