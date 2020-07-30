# gem install benchmark-ips
require 'thread'
require "benchmark/ips"

h = { a: { b: 0 } }
Thread.current.thread_variable_set(:a, { b: 0 })

Benchmark.ips do |x|
  x.report("baseline") { h[:a][:b] += 1 }
  x.report("secondary") { a = h[:a]; a[:b] += 1 }
  x.report("dig") { a = h.dig(:a, :b); a += 1 }
  x.report("TLS") { Thread.current.thread_variable_get(:a)[:b] += 1 }
end
