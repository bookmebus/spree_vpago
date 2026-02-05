module Vpago
  module TimingHelper
    # Gets the current monotonic timestamp.
    #
    # @return [Float] current timestamp from Process.clock_gettime(Process::CLOCK_MONOTONIC)
    def self.current_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # Measures elapsed time in milliseconds from a given start timestamp.
    #
    # @param started_at [Float] timestamp from Process.clock_gettime(Process::CLOCK_MONOTONIC)
    # @return [Float] elapsed time in milliseconds, rounded to 1 decimal place
    def self.elapsed_ms(started_at)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000.0).round(1)
    end

    # Yields to a block and measures its execution time in milliseconds.
    #
    # @yield the block to measure
    # @return [Float] elapsed time in milliseconds, rounded to 1 decimal place
    def self.measure_ms
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
      elapsed_ms(started_at)
    end
  end
end
