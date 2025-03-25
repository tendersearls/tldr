class TLDR
  Test = Struct.new(:test_class, :method_name) do
    attr_reader :file, :line, :location

    def initialize(*args)
      super
      @file, @line = SorbetCompatibility.unwrap_method(test_class.instance_method(method_name)).source_location
      @location = Location.new(file, line)
    end

    # Test exact match starting line condition first to save us a potential re-parsing to look up end_line
    def covers_line? l
      line == l || (l >= line && l <= end_line)
    end

    def group?
      false
    end

    private

    # Memoizing at call time, because re-parsing isn't free and isn't usually necessary
    def end_line
      @end_line ||= begin
        test_method = SorbetCompatibility.unwrap_method(test_class.instance_method(method_name))
        if RubyUtil.parsing_with_prism?
          RubyUtil.find_prism_def_node_for(test_method)&.end_line || -1
        else
          RubyVM::AbstractSyntaxTree.of(test_method).last_lineno
        end
      end
    end
  end
end
