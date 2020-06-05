#!/usr/bin/env ruby -v

require 'active_support'
require 'active_support/core_ext'

input = [ 1..5, 21..29, 2..6, 12..15, 10..13, 2..4 ]
results = []

def join_ranges(left, right)
  [left.begin, right.begin].min..[left.end, right.end].max
end

p input

input.each do |x|
  c = nil
  results.each do |r|
    if r[:union].overlaps? x
      c = r
      break
    end
  end
  if c.nil?
    c = { union: x }
    results.append c
  end
  c[:union] = join_ranges c[:union], x
end

p results.map { |x| x[:union] }
