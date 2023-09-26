require "test_helper"

class TLDR
  class StrategizerTest < Minitest::Test
    def setup
      @subject = Strategizer.new
    end

    def test_no_groups
      result = @subject.strategize some_tests, []

      assert_equal some_tests, result.tests
      assert_equal some_tests, result.tests_and_groups
    end

    def test_basic_group
      some_groups = [
        TestGroup.new([[TB, :test_2], ["TLDR::StrategizerTest::TC", :test_1]])
      ]

      result = @subject.strategize some_tests, some_groups

      assert_equal some_tests, result.tests
      assert_equal [
        Test.new(TA, :test_1),
        Test.new(TA, :test_2),
        Test.new(TB, :test_1),
        TestGroup.new([[TB, :test_2], ["TLDR::StrategizerTest::TC", :test_1]]),
        Test.new(TC, :test_2)
      ], result.tests_and_groups
      assert_equal [
        Test.new(TB, :test_2),
        Test.new(TC, :test_1)
      ], result.tests_and_groups[3].tests
    end

    def test_overlapping_groups_where_a_test_appears_in_multiple_groups
      some_groups = [
        TestGroup.new([[TB, :test_2], ["TLDR::StrategizerTest::TC", :test_1]]),
        TestGroup.new([["TLDR::StrategizerTest::TB", :test_2], [TA, :test_1]])
      ]

      result = @subject.strategize some_tests, some_groups

      assert_equal some_tests, result.tests
      assert_equal [
        Test.new(TB, :test_2),
        Test.new(TA, :test_1),
        Test.new(TC, :test_1)
      ], result.tests_and_groups.first.tests
      assert_equal some_tests - [
        Test.new(TA, :test_1),
        Test.new(TB, :test_2),
        Test.new(TC, :test_1)
      ], result.tests_and_groups[1..]
    end

    def test_weird_repitition
      some_groups = [
        TestGroup.new([[TA, nil]]),
        TestGroup.new([[TA, nil]]),
        TestGroup.new([[TA, nil], [TB, :test_2]]),
        TestGroup.new([[TA, :test_2], [TC, :test_1]]),
        TestGroup.new([[TB, :test_2], [TC, :test_2]])
      ]

      result = @subject.strategize some_tests, some_groups

      assert_equal some_tests, result.tests
      assert_equal 2, result.tests_and_groups.size
      assert_equal [
        Test.new(TA, :test_1),
        Test.new(TA, :test_2),
        Test.new(TB, :test_2),
        Test.new(TC, :test_1),
        Test.new(TC, :test_2)
      ], result.tests_and_groups.first.tests
      assert_equal Test.new(TB, :test_1), result.tests_and_groups[1]
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
  end
end
