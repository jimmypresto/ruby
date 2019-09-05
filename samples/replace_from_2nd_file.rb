#!/usr/bin/env ruby -w

require_relative 'replace'

p "From 2nd file: " + Foo.new.method
p "From 2nd file: " + Foo.new.method2

