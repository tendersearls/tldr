require_relative "../test_helper"

class TLDR
  class StrategizerTest < Minitest::Test
    class TA < TLDR
      def test_1
      end

      def test_2
      end
    end

    class TB < TLDR
      def test_1
      end

      def test_2
      end
    end

    class TC < TLDR
      def test_1
      end

      def test_2
      end
    end

    def setup
      @subject = Strategizer.new
    end

    def test_no_groups
      result = @subject.strategize(some_tests, [], [], Config.new(prepend_paths: []))

      assert result.parallel?
      assert_equal some_tests, result.parallel_tests_and_groups
      assert_equal [], result.append_sequential_tests
    end

    def test_one_test
      tests = [Test.new(TA, :test_1)]

      result = @subject.strategize(tests, [], [], Config.new(prepend_paths: []))

      refute result.parallel?
    end

    def test_parallel_disabled
      result = @subject.strategize(some_tests, [], [], Config.new(prepend_paths: [], parallel: false))

      refute result.parallel?
    end

    def test_basic_group
      some_groups = [
        TestGroup.new([[TB, :test_2], ["TLDR::StrategizerTest::TC", :test_1]])
      ]

      result = @subject.strategize(some_tests, some_groups, [], Config.new(prepend_paths: []))

      assert result.parallel?
      assert_equal [
        Test.new(TA, :test_1),
        Test.new(TA, :test_2),
        Test.new(TB, :test_1),
        TestGroup.new([[TB, :test_2], ["TLDR::StrategizerTest::TC", :test_1]]),
        Test.new(TC, :test_2)
      ], result.parallel_tests_and_groups
      assert_equal [
        Test.new(TB, :test_2),
        Test.new(TC, :test_1)
      ], result.parallel_tests_and_groups[3].tests
    end

    def test_overlapping_groups_where_a_test_appears_in_multiple_groups
      some_groups = [
        TestGroup.new([[TB, :test_2], ["TLDR::StrategizerTest::TC", :test_1]]),
        TestGroup.new([["TLDR::StrategizerTest::TB", :test_2], [TA, :test_1]])
      ]

      result = @subject.strategize(some_tests, some_groups, [], Config.new(prepend_paths: []))

      assert result.parallel?
      assert_equal [
        Test.new(TB, :test_2),
        Test.new(TA, :test_1),
        Test.new(TC, :test_1)
      ], result.parallel_tests_and_groups.first.tests
      assert_equal some_tests - [
        Test.new(TA, :test_1),
        Test.new(TB, :test_2),
        Test.new(TC, :test_1)
      ], result.parallel_tests_and_groups[1..]
    end

    def test_weird_repetition
      some_groups = [
        TestGroup.new([[TA, nil]]),
        TestGroup.new([[TA, nil]]),
        TestGroup.new([[TA, nil], [TB, :test_2]]),
        TestGroup.new([[TA, :test_2], [TC, :test_1]]),
        TestGroup.new([[TB, :test_2], [TC, :test_2]])
      ]
      unsafe_groups = [
        TestGroup.new([[TA, :test_2]]),
        TestGroup.new([[TB, :test_1]])
      ]

      result = @subject.strategize(some_tests, some_groups, unsafe_groups, Config.new(prepend_paths: []))

      assert result.parallel?
      assert_equal 2, result.parallel_tests_and_groups.size
      assert_equal [
        Test.new(TA, :test_1),
        Test.new(TB, :test_2),
        Test.new(TC, :test_2)
      ], result.parallel_tests_and_groups.first.tests
      assert_equal Test.new(TC, :test_1), result.parallel_tests_and_groups[1]
      assert_equal [
        Test.new(TA, :test_2),
        Test.new(TB, :test_1)
      ], result.append_sequential_tests
    end

    def test_append_sequential_tests
      unsafe_groups = [
        TestGroup.new([[TA, nil], [TB, :test_2]])
      ]

      result = @subject.strategize(some_tests, [], unsafe_groups, Config.new(prepend_paths: []))

      assert result.parallel?
      assert_equal some_tests - [
        Test.new(TA, :test_1),
        Test.new(TA, :test_2),
        Test.new(TB, :test_2)
      ], result.parallel_tests_and_groups
      assert_equal [
        Test.new(TA, :test_1),
        Test.new(TA, :test_2),
        Test.new(TB, :test_2)
      ], result.append_sequential_tests
    end

    def test_append_sequential_tests_with_prepend
      unsafe_groups = [
        TestGroup.new([[TA, nil], [TB, :test_2]])
      ]

      result = @subject.strategize(some_tests, [], unsafe_groups, Config.new(prepend_paths: ["tests/tldr/strategizer_test.rb:18"]))

      assert_equal [Test.new(TB, :test_2)], result.prepend_sequential_tests
      assert_equal some_tests - [
        Test.new(TA, :test_1),
        Test.new(TA, :test_2),
        Test.new(TB, :test_2)
      ], result.parallel_tests_and_groups
      assert_equal [
        Test.new(TA, :test_1),
        Test.new(TA, :test_2)
      ], result.append_sequential_tests
    end

    def test_grouped_tests_that_arent_selected_by_the_runner
      some_groups = [
        TestGroup.new([[TA, nil]]),
        TestGroup.new([[TB, :test_1], [TB, :test_2]])
      ]
      unsafe_groups = [
        TestGroup.new([[TC, nil]])
      ]

      result = @subject.strategize([
        Test.new(TA, :test_1),
        Test.new(TC, :test_2)
      ], some_groups, unsafe_groups, Config.new(prepend_paths: []))

      assert result.parallel?
      assert_equal [
        Test.new(TA, :test_1)
      ], result.parallel_tests_and_groups
      assert_equal [
        Test.new(TC, :test_2)
      ], result.append_sequential_tests
    end

    private

    def some_tests
      [
        Test.new(TA, :test_1),
        Test.new(TA, :test_2),
        Test.new(TB, :test_1),
        Test.new(TB, :test_2),
        Test.new(TC, :test_1),
        Test.new(TC, :test_2)
      ]
    end
  end
end
