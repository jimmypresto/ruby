#!/usr/bin/env ruby -w

module Util
  def self.xlat(a, b)
    i = (a.to_s.empty?? 0x00 : 0x01) + (b.to_s.empty?? 0x00 : 0x02)
    xlat = [
      ->(a1, b1) { "No a and b" },
      ->(a1, b1) { "I have a: %s" % a1 },
      ->(a1, b1) { "I have b: %s" % b1 },
      ->(a1, b1) { "I have both a: %s and b: %s" % [ a1, b1 ] },
    ]
    puts xlat[i & 0x03].call(a, b)
  end
end

Util.xlat(nil, '')
Util.xlat('a', nil)
Util.xlat(nil, 'b')
Util.xlat('a', 'b')
