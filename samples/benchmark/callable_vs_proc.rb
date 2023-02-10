require 'benchmark'
require 'benchmark/ips'

puts "Ruby version: #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"

def BaselineFunction(a, b, c, d, e)
end

class CallableWithFiveArgsClass
  public def call a, b, c, d, e
    BaselineFunction(a, b, c, d, e)
  end
end

CallableWithFiveArgs = CallableWithFiveArgsClass.new
ProcWithFiveArgs = proc { |a, b, c, d, e| BaselineFunction(a, b, c, d, e) }

Benchmark.ips do |x|
  x.report("Baseline") { BaselineFunction 1,2,3,4,5 }
  x.report("Callable") { CallableWithFiveArgs.call 1,2,3,4,5 }
  x.report("Proc") { ProcWithFiveArgs.call 1,2,3,4,5 }
end

puts "Baseline 10k call: %s" % Benchmark.measure {
  10_000.times do
    BaselineFunction 1,2,3,4,5
  end
}

puts "Callable 10k call: %s" % Benchmark.measure {
  10_000.times do
    CallableWithFiveArgs.call 1,2,3,4,5
  end
}

puts "   Proc 10k calls: %s" % Benchmark.measure {
  10_000.times do
    ProcWithFiveArgs.call 1,2,3,4,5
  end
}
