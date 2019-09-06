#!/usr/bin/env ruby -w
# frozen_string_literal: true

require 'typhoeus'

module Typhoeus
  RECORD_OUTPUT_DIR = '/tmp'
  RECORD_FILENAME_PREFIX = "typhoeus_record_"
  class Request
    def on_complete_and_record(response)
      record_response(response)
      on_complete_user = response.request.instance_variable_get(:@on_complete_user)
      on_complete_user.each do |callback|
        callback.call(response)
      end
    end

    def record_response(response)
      return if response.nil?
      url = response.effective_url
      filename = url.to_s.gsub(/[:\/\.\&\?\=\%]/, '_')
      filename = File.join(RECORD_OUTPUT_DIR, RECORD_FILENAME_PREFIX + filename)
      response = response.clone
      response.request = nil
      #response.request.instance_variable_set(:@on_complete, [])
      #response.request.instance_variable_set(:@on_complete_user, [])
      #response.request.instance_variable_set(:@on_progress, [])
      #response.request.instance_variable_set(:@on_success, [])
      obj_blob = Object::Marshal.dump response
      File.open(filename, 'w') do |file|
        file.puts obj_blob
      end
    end

    def self.override_on_complete(request) 
      request.instance_variable_set(:@on_complete_user, request.on_complete.clone)
      on_complete_ours = Request.instance_method(:on_complete_and_record).bind(request)
      request.on_complete.clear
      request.on_complete do |response|
        on_complete_ours.call(response)
      end
    end
  end

  class Hydra
    old_queue = instance_method(:queue)

    define_method(:queue) do |*args|
      request, * = args
      Request.override_on_complete request
      old_queue.bind(self).call(*args)
   end
  end
end
 
url = 'https://raw.githubusercontent.com/jimmypresto/perf/master/ffmpeg.txt'
r = Typhoeus::Request.new(url)
r.on_complete do |response|
  p response.effective_url
  p response.response_headers
  p response.response_body
end

hydra = Typhoeus::Hydra.new
hydra.queue r
hydra.run

p ""
Dir.glob(File.join(Typhoeus::RECORD_OUTPUT_DIR, Typhoeus::RECORD_FILENAME_PREFIX + "*")) do |file|
  response = Marshal.load File.read(file)
  p "RECORD === #{file} ==="
  p response.effective_url
  p response.response_headers
  p response.response_body
  p ""
end
