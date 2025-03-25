class TLDR
  module RubyUtil
    def self.parsing_with_prism?
      RubyVM::InstructionSequence.compile("").to_a[4][:parser] == :prism
    end

    def self.find_prism_def_node_for(method)
      require "prism"

      iseq = RubyVM::InstructionSequence.of(method).to_a
      method_metadata = iseq[4]
      method_name = iseq[5]

      file_path, line_number = method.source_location
      parse_prism_ast(file_path).breadth_first_search { |node|
        node.type == :def_node &&
          line_number == node.start_line &&
          method_name == node.name.to_s &&
          method_metadata[:code_location] == [node.start_line, node.start_column, node.end_line, node.end_column]
      }
    end

    def self.parse_prism_ast(file_path)
      @prism_ast = Thread.current[:prism_parse_results] ||= {}
      @prism_ast[file_path] ||= Prism.parse(File.read(file_path)).value
    end
  end
end
