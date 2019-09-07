#!/usr/bin/env ruby -w
# frozen_string_literal: true

require 'typhoeus'

module Typhoeus
  RECORD_MODE_NONE = 0
  RECORD_MODE_RECORD = 1
  RECORD_MODE_REPLAY = 2
  class << self
    attr_accessor :record_mode
  end

  Typhoeus.record_mode = Typhoeus::RECORD_MODE_REPLAY
  RECORD_OUTPUT_DIR = '/tmp'
  RECORD_FILENAME_PREFIX = "typhoeus_record_"

  class Request
    def run_on_complete_user(response)
      @on_complete_user.each do |callback|
        callback.call(response)
      end
    end

    def on_complete_and_record(response)
      record_response(response)
      run_on_complete_user(response)
    end

    def url_to_filename(url)
      filename = url.to_s.gsub(/[:\/\.\&\?\=\%\+\-]+/, '_')
      File.join(RECORD_OUTPUT_DIR, RECORD_FILENAME_PREFIX + filename)
    end

    def record_response(response)
      return if response.nil?
      filename = url_to_filename(response.effective_url)
      response = response.clone
      # TODO: unmarshallable members: on_complete/on_complete_user/on_progress/on_success/etc
      response.request = nil
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

    def replay_recorded_response
      filename = url_to_filename(@base_url)
      response = Object::Marshal.load File.read(filename)
      @on_complete_user = on_complete.clone
      run_on_complete_user(response)
    end

    old_run = instance_method(:run)
    define_method(:run) do |*args|
      case Typhoeus.record_mode
      when Typhoeus::RECORD_MODE_RECORD
        Request.override_on_complete self
        old_run.bind(self).call(*args)
      when Typhoeus::RECORD_MODE_REPLAY
        self.replay_recorded_response
      end
    end
  end

  class Hydra
    old_queue = instance_method(:queue)
    define_method(:queue) do |*args|
      request, * = args
      case Typhoeus.record_mode
      when Typhoeus::RECORD_MODE_RECORD
        Request.override_on_complete request
        old_queue.bind(self).call(*args)
      when Typhoeus::RECORD_MODE_REPLAY
        old_queue.bind(self).call(*args)
      end
    end

    old_run = instance_method(:run)
    define_method(:run) do |*args|
      case Typhoeus.record_mode
      when Typhoeus::RECORD_MODE_REPLAY
        self.queued_requests.each do |request|
          request.replay_recorded_response
        end
      else
        old_run.bind(self).call(*args)
      end
    end
  end
end
 
url = 'https://raw.githubusercontent.com/jimmypresto/perf/master/ffmpeg.txt'
r = Typhoeus::Request.new(url)
r.on_complete do |response|
  p "on_complete: " + response.effective_url
  p "on_complete: " + response.response_headers
  p "on_complete: " + response.response_body
end

r.run
# hydra = Typhoeus::Hydra.new
# hydra.queue r
# hydra.run
 
p ""
Dir.glob(File.join(Typhoeus::RECORD_OUTPUT_DIR, Typhoeus::RECORD_FILENAME_PREFIX + "*")) do |file|
  response = Marshal.load File.read(file)
  p "RECORD === #{file} ==="
  p response.effective_url
  p response.response_headers
  p response.response_body
  p ""
end
