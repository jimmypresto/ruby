require 'benchmark/ips'

def methodA(a:, b:, c:)
end

def baseline_hash_explicit_pickup(args_hash)
  methodA(a: args_hash[:a], b: args_hash[:b], c: args_hash[:c])
end

Benchmark.ips do |x|
  x.report("baseline") { methodA(a: 1, b: 2, c: 3) }
  x.report("baseline_hash_explicit_pickup") { baseline_hash_explicit_pickup({ a: 1, b: 2, c: 3 }) }
  x.report("direct_args_hash_passing") { methodA({ a: 1, b: 2, c: 3 }) }
end
