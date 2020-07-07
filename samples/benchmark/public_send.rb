# gem install benchmark-ips
require "benchmark/ips"

class A
  def initialize(); end
  def a_method(); end
end

Benchmark.ips do |x|
  x.report("an instance method direct call") { A.new.a_method }
  x.report("an instance method call via .public_send") { A.new.public_send(:a_method) }
end
