#!/usr/bin/env ruby -w
# frozen_string_literal: true

require 'typhoeus'
require_relative 'typhoeus_dvr'
require 'benchmark'
require 'byebug'

byebug
TyphoeusDVR.record_mode = TyphoeusDVR::RECORD_MODE_RECORD
url = 'https://raw.githubusercontent.com/jimmypresto/ruby/master/samples/Gemfile'
request = Typhoeus::Request.new url
body = ''
request.on_complete do |response|
  body = response.response_body
end
request.run
fail if body == ""

filename = request.url_to_filename url
str = File.read(filename).gsub('typhoeus', 'TYPHOEUS')
File.write(filename, str)

body = ''
TyphoeusDVR.record_mode = TyphoeusDVR::RECORD_MODE_REPLAY
request.run
fail if body == ""

body = ''
hydra = Typhoeus::Hydra.new
hydra.queue request
hydra.run
fail if body == ""

puts Benchmark.measure {
  request.on_complete.clear
  request.on_complete do |response|
    fail if response.response_body != body
  end
  10_000.times do
    TyphoeusDVR.record_mode = TyphoeusDVR::RECORD_MODE_REPLAY
    request.run
  end
}
