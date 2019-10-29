#!/usr/bin/env ruby -w
#
require 'concurrent'
started_t = Time.now
map = Concurrent::Map.new
threads = []
(1..10).each { |i| 
  threads << Thread.new(i) { |j|
    10_000.times {
      map.compute(j) {
        (Time.now - started_t) + rand(10_000)
      }
    }
  }
}
threads.each { |t| t.join }


