class TLDR
  module Reporters
    class Base
      def before_suite tldr_config, tests
      end

      def after_test test_result
      end

      def after_tldr tldr_config, planned_tests, wip_tests, test_results
      end

      def after_suite tldr_config, test_results
      end
    end
  end
end
