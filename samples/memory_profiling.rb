#!/bin/ruby
# frozen_string_literal: true

# See increases of free objects between 2nd and 3rd GC.stat
# ruby memory_profiling.rb  | grep  ':total_freed_objects.[^,]*'

# A type that can hold another thing
class A
  attr_accessor :holding
end

GC.enable
GC.start
GC.disable
p GC.stat

1000.times do
  a1 = A.new
  a2 = A.new
  a3 = A.new
  a1.holding = a2
  a2.holding = a3
  a3.holding = a1
end
p GC.stat

GC.enable
GC.start
p GC.stat
  
