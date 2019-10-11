# frozen_string_literal: true

require 'benchmark'
require 'Concurrent'

module TyphoeusDVR
  RECORD_MODE_NONE ||= 0
  RECORD_MODE_RECORD ||= 1
  RECORD_MODE_REPLAY ||= 2

  RECORD_OUTPUT_DIR ||= ENV['TYPHOEUS_DVR_OUTPUT_DIR'] if ENV.key?('TYPHOEUS_DVR_OUTPUT_DIR')
  RECORD_OUTPUT_DIR ||= '/tmp' # Use tmp as it may be mapped to memory
  RECORD_FILENAME_PREFIX ||= ENV['TYPHOEUS_DVR_FILENAME_PREFIX'] if ENV.key?('TYPHOEUS_DVR_FILENAME_PREFIX')
  RECORD_FILENAME_PREFIX ||= "typhoeus_record_"

  class << self
    attr_accessor :record_mode
    attr_accessor :use_replay_time
    attr_accessor :response_caching_enabled
    attr_accessor :response_cache
  end

  TyphoeusDVR.record_mode = ENV['TYPHOEUS_DVR_MODE'].to_i if ENV.key?('TYPHOEUS_DVR_MODE')
  TyphoeusDVR.record_mode ||= TyphoeusDVR::RECORD_MODE_NONE
  TyphoeusDVR.use_replay_time = ENV['TYPHOEUS_USE_REPLAY_TIME'].to_i if ENV.key?('TYPHOEUS_USE_REPLAY_TIME')
  TyphoeusDVR.use_replay_time ||= 0
  TyphoeusDVR.response_caching_enabled = ENV['TYPHOEUS_DVR_RESPONSE_CACHING_ENABLED'].to_i if ENV.key?('TYPHOEUS_DVR_RESPONSE_CACHING_ENABLED')
  TyphoeusDVR.response_caching_enabled ||= true

  TyphoeusDVR.response_cache = Concurrent::Map.new
end

module Typhoeus
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
      # Remove environment specific variables (e.g. scheme, host, port)      
      uri = URI.parse(url)
      yammer_options = self.yammer_options if self.respond_to? :yammer_options
      unless yammer_options.nil?
        uri.scheme = 'HTTP'
        uri.host = yammer_options[:service_name]
        uri.port = nil
      end
      filename = uri.to_s.gsub(/[:\/\.\&\?\=\%\+\-]+/, '_')
      File.join(TyphoeusDVR::RECORD_OUTPUT_DIR, TyphoeusDVR::RECORD_FILENAME_PREFIX + filename)
    end

    def record_response(response)
      return if response.nil?
      filename = url_to_filename(response.effective_url)

      # Request object is not marshallable, because Proc members, nullify it before we serialize the response object
      # Later on when we deserialize response back, we have to use caller's request object and stash it in re-created response object
      recorded_response = response.clone
      recorded_response.request = nil

      if TyphoeusDVR.response_caching_enabled
        TyphoeusDVR.response_cache.compute_if_absent(filename) { write_recorded_response_to_file(filename, recorded_response) }
      else
        write_recorded_response_to_file(filename, recorded_response)
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

    def write_recorded_response_to_file(filename, response)
      obj_blob = Object::Marshal.dump response
      File.open(filename, 'wb') do |file|
        file.puts obj_blob
      end

      response
    end

    def replay_recorded_response
      elapsed_seconds = Benchmark.realtime do
        filename = url_to_filename(@base_url)
        self.response = get_recorded_response(filename)
        self.response.request = self
        run_before_callback
      end
      self.response.options[:total_time] = elapsed_seconds if TyphoeusDVR.use_replay_time
      @on_complete_user = on_complete.clone
      run_on_complete_user(self.response)
      self.response
    end

    def get_recorded_response(filename)
      if TyphoeusDVR.response_caching_enabled
        cached_response = TyphoeusDVR.response_cache.fetch_or_store(filename) { |fn| read_recorded_response_from_file(fn) }
        loaded_response = cached_response.clone
      else
        loaded_response = read_recorded_response_from_file(filename)
      end

      loaded_response
    end

    def read_recorded_response_from_file(filename)
      cached_response = Object::Marshal.load File.read(filename)
      cached_response.request = nil

      cached_response
    end

    old_run = instance_method(:run)
    define_method(:run) do |*args|
      case TyphoeusDVR.record_mode
      when TyphoeusDVR::RECORD_MODE_RECORD
        Request.override_on_complete self
        old_run.bind(self).call(*args)
      when TyphoeusDVR::RECORD_MODE_REPLAY
        self.replay_recorded_response
      else
        old_run.bind(self).call(*args)
      end
    end
  end

  class Hydra
    old_queue = instance_method(:queue)
    define_method(:queue) do |*args|
      request, * = args
      case TyphoeusDVR.record_mode
      when TyphoeusDVR::RECORD_MODE_RECORD
        Request.override_on_complete request
        old_queue.bind(self).call(*args)
      when TyphoeusDVR::RECORD_MODE_REPLAY
        old_queue.bind(self).call(*args)
      else
        old_queue.bind(self).call(*args)
      end
    end

    old_run = instance_method(:run)
    define_method(:run) do |*args|
      case TyphoeusDVR.record_mode
      when TyphoeusDVR::RECORD_MODE_REPLAY
        self.queued_requests.each do |request|
          request.replay_recorded_response
        end
      else
        old_run.bind(self).call(*args)
      end
    end
  end
end
