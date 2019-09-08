#!/usr/bin/env ruby -w
# frozen_string_literal: true

require 'typhoeus'
require_relative 'typhoeus_dvr'

url = 'https://raw.githubusercontent.com/jimmypresto/ruby/master/samples/Gemfile'
request = Typhoeus::Request.new url
request.on_complete do |response|
  p response.response_body
end
request.run

filename = request.url_to_filename url
str = File.read(filename).gsub('typhoeus', 'TYPHOEUS')
File.write(filename, str)

Typhoeus.record_mode = Typhoeus::RECORD_MODE_REPLAY
request.run

hydra = Typhoeus::Hydra.new
hydra.queue request
hydra.run
