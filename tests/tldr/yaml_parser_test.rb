require_relative "../test_helper"

class YamlParserTest < Minitest::Test
  def setup
    @subject = TLDR::YamlParser.new
  end

  def test_yaml_file_paths_globbing
    yaml = <<~YAML
      paths:
        - lib/tldr/yaml_*.rb
        - "tests/tldr/yaml_parser_test.rb"
    YAML
    with_temp_file "foo.yml", yaml do |yaml_path|
      assert_equal({paths: [
        "lib/tldr/yaml_parser.rb",
        "tests/tldr/yaml_parser_test.rb"
      ]}, @subject.parse(yaml_path))
    end
  end

  class FauxReporter
  end

  def test_reporter_lookup
    with_temp_file "foo.yml", "reporter: YamlParserTest::FauxReporter" do |yaml_path|
      assert_equal({reporter: FauxReporter}, @subject.parse(yaml_path))
    end

    with_temp_file "foo.yml", "reporter: UnknownReporter" do |yaml_path|
      e = assert_raises(TLDR::Error) do
        @subject.parse(yaml_path)
      end
      assert_equal "Unknown reporter 'UnknownReporter' specified in foo.yml file", e.message
    end
  end

  def test_yaml_file_translating_timeout_values
    with_temp_file "foo.yml", "timeout: true" do |yaml_path|
      assert_equal({timeout: TLDR::Config::DEFAULT_TIMEOUT}, @subject.parse(yaml_path))
    end

    with_temp_file "foo.yml", "timeout: false" do |yaml_path|
      assert_equal({timeout: -1}, @subject.parse(yaml_path))
    end

    with_temp_file "foo.yml", "timeout: null" do |yaml_path|
      assert_equal({timeout: nil}, @subject.parse(yaml_path))
    end

    with_temp_file "foo.yml", "timeout: 42.3" do |yaml_path|
      assert_equal({timeout: 42.3}, @subject.parse(yaml_path))
    end

    with_temp_file "foo.yml", "timeout: '42.3'" do |yaml_path|
      assert_equal({timeout: 42.3}, @subject.parse(yaml_path))
    end
  end

  def test_bs_args_error
    with_temp_file ".sure_jan.yml", "boyfriend: George Glass" do |yaml_path|
      e = assert_raises(TLDR::Error) do
        @subject.parse(yaml_path)
      end
      assert_equal "Invalid keys in .sure_jan.yml file: boyfriend", e.message
    end
  end
end
