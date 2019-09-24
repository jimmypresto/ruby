#!/usr/bin/env ruby -w
# frozen_string_literal: true

module Typhoeus
  RECORD_MODE_NONE = 0
  RECORD_MODE_RECORD = 1
  RECORD_MODE_REPLAY = 2
  class << self
    attr_accessor :record_mode
  end

  Typhoeus.record_mode = ENV['TYPHOEUS_DVR_MODE'].to_i if ENV.key?('TYPHOEUS_DVR_MODE')
  Typhoeus.record_mode ||= Typhoeus::RECORD_MODE_RECORD
  RECORD_OUTPUT_DIR ||= '/tmp'
  RECORD_FILENAME_PREFIX ||= "typhoeus_record_"

  class Request
    def run_before_callback
      return if Typhoeus.before.nil?
      Typhoeus.before.each do |callback|
        callback.call(self)
      end
    end

    def run_on_complete_user(response)
      return if @on_complete_user.nil?
      @on_complete_user.each do |callback|
        callback.call(response) unless callback.to_s.include?("typhoeus_dvr.rb")
      end
      @on_complete = @on_complete_user.clone
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
      # Requrest object is not marshallable, cuz Proc members, nullify it before we serialize the response object
      # Later on when we deserialize response back, we have to use caller's request object and stash it in re-created response object
      response.request = nil
      obj_blob = Object::Marshal.dump response
      File.open(filename, 'wb') do |file|
        file.puts obj_blob
      end
    end

    def self.override_on_complete(request) 
      unless request.on_complete.to_s.include? "typhoeus_dvr.rb"
        request.instance_variable_set(:@on_complete_user, request.on_complete.clone)
      end
      on_complete_ours = Request.instance_method(:on_complete_and_record).bind(request)
      request.on_complete.clear
      request.on_complete do |response|
        on_complete_ours.call(response)
      end
    end

    def replay_recorded_response
      filename = url_to_filename(@base_url)
      self.response = Object::Marshal.load File.read(filename)
      self.response.request = self
      run_before_callback
      @on_complete_user = on_complete.clone
      run_on_complete_user(self.response)
      self.response
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
