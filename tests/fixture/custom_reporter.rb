class SuitReporter
  def before_suite tests
  end

  def after_test test_result
    print case test_result.type
    when :success then "♠︎"
    when :skip then "♣︎"
    when :failure then "♥︎"
    when :error then "♦︎"
    end
  end

  def after_suite test_results
  end

  def after_tldr planned_tests, wip_tests, test_results
  end

  def after_fail_fast planned_tests, wip_tests, test_results, last_result
  end
end
