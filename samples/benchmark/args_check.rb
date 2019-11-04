require 'benchmark/ips'

def baseline(args)
  (args.class == [].class) && (args.length == 1) && (args.first.class == {}.class)
end

def a_faster_version(args)
  args&.first&.is_a?(Hash) == true
end

Benchmark.ips do |x|
  x.report("baseline_first_array_element_is_hash") { baseline([{}]) }
  x.report("a_faster_version") { a_faster_version([{}]) }
end
