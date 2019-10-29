# gem install benchmark-ips
require "benchmark/ips"

def option_hash(options = {}); end
def double_splat(**options); end
def single_splat(*options); end

Benchmark.ips do |x|
  x.report("option_hash") { option_hash(foo: 1, bar: 2) }
  x.report("double_splat") { double_splat(foo: 1, bar: 2) }
  x.report("single_splat") { single_splat(foo: 1, bar: 2) }
end
