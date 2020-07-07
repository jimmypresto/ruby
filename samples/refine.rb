#!/usr/bin/env ruby -w

require 'byebug'

module AA
  refine String do
    def hello
      "hello, #{to_s}"
    end
  end
end

using AA
p 'world'.hello # this works

require_relative 'refine_subordinate'

p AA.dd # NoMethodError

