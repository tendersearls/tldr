module Timer
  module_function

  def time unit = :microsecond
    Process.clock_gettime(Process::CLOCK_MONOTONIC, unit)
  end

  def time_it start = time
    yield
    time_diff start
  end

  def time_diff start, stop = time
    ((stop - start) / 1000.0).round
  end
end