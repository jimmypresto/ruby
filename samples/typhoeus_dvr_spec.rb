#!/usr/bin/env ruby -w
# frozen_string_literal: true

require 'minitest/autorun'
require 'typhoeus'
require_relative 'typhoeus_dvr'

def remove_previous_record(request)
  filename = request.url_to_filename(@url)
  File.delete filename if File.exist?(filename)
  File.exist?(filename).must_equal false
end

def verify_response(response, url)
  response.wont_be_nil
  response.effective_url.must_equal url
  nil
end

def verify_recorded_file(filename, url)
  File.exist?(filename).must_equal true
  File.read(filename).include?(url).must_equal true
end

class TyphoeusDvrSpec < Minitest::Test
  describe "TyphoeusDvrSpec" do
    before do
      @url = 'http://fubar/'
      @request = Typhoeus::Request.new @url
      @filename = @request.url_to_filename(@url)
      remove_previous_record @request
    end

    after do
      remove_previous_record @request
    end

    describe "EnvironmentVariable" do
      it "Should overwrite the record mode variable" do
        ENV['TYPHOEUS_DVR_MODE'] = TyphoeusDVR::RECORD_MODE_NONE.to_s
        load "typhoeus_dvr.rb"
        TyphoeusDVR.record_mode.must_equal TyphoeusDVR::RECORD_MODE_NONE
        ENV['TYPHOEUS_DVR_MODE'] = TyphoeusDVR::RECORD_MODE_RECORD.to_s
        load "typhoeus_dvr.rb"
        TyphoeusDVR.record_mode.must_equal TyphoeusDVR::RECORD_MODE_RECORD
        ENV['TYPHOEUS_DVR_MODE'] = TyphoeusDVR::RECORD_MODE_REPLAY.to_s
        load "typhoeus_dvr.rb"
        TyphoeusDVR.record_mode.must_equal TyphoeusDVR::RECORD_MODE_REPLAY
        ENV.delete('TYPHOEUS_DVR_MODE')
      end
    end

    describe "RecordMode" do
      it "Should write response to file too" do

        # This test directly manipulates response file and expects dvr to read the changed file
        # Without diabling caching, dvr may still return the unchanged file content back
        TyphoeusDVR.response_caching_enabled = false
        TyphoeusDVR.response_cache = Concurrent::Map.new

        received = false 
        TyphoeusDVR.record_mode = TyphoeusDVR::RECORD_MODE_RECORD
        @request = Typhoeus::Request.new @url
        @request.on_complete.clear
        @request.on_complete do |response|
          verify_response(response, @url)
          verify_recorded_file(@filename, @url)
          received = true
        end
        @request.run
        received.must_equal true

        # Do it again using Hydra
        received = false 
        remove_previous_record @request
        hydra = Typhoeus::Hydra.new
        hydra.queue @request
        hydra.run
        received.must_equal true
        verify_recorded_file(@filename, @url)
      end
    end

    describe "ReplayMode" do
      it "Should replay response from file" do

        # This test directly manipulates response file and expects dvr to read the changed file
        # Without diabling caching, dvr may still return the unchanged file content back
        TyphoeusDVR.response_caching_enabled = false
        TyphoeusDVR.response_cache = Concurrent::Map.new

        # First create a new record file
        received = false 
        TyphoeusDVR.record_mode = TyphoeusDVR::RECORD_MODE_RECORD
        @request = Typhoeus::Request.new @url
        @request.on_complete do |response|
          verify_response(response, @url)
          verify_recorded_file(@filename, @url)
          received = true
        end
        @request.run
        received.must_equal true

        # Calibrate record file to snafu url
        blob = File.read(@filename)
        blob = blob.gsub(/fubar/, 'snafu')
        File.write(@filename, blob)
        calibrated_url = 'http://snafu/'

        # Now in replay mode
        received = false 
        TyphoeusDVR.record_mode = TyphoeusDVR::RECORD_MODE_REPLAY
        @request.on_complete.clear
        @request.on_complete do |response|
          verify_response(response, calibrated_url)
          received = true
        end
        @request.run
        received.must_equal true

        # Do it again using Hydra
        received = false 
        hydra = Typhoeus::Hydra.new
        hydra.queue @request
        hydra.run
        received.must_equal true
      end
    end
  end
end
