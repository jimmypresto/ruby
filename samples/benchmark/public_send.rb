# gem install benchmark-ips
require "benchmark/ips"

class A
  def initialize(); end
  def instance_method(); end
  def self.class_method(); end
end

Benchmark.ips do |x|
  x.report("a class method direct call") { A.class_method }
  x.report("an instance method direct call") { A.new.instance_method }
  x.report("an instance method call via .public_send") { A.new.public_send(:instance_method) }
end
