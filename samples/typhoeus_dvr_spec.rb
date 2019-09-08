#!/usr/bin/env ruby -w
# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'typhoeus_dvr'
require 'typhoeus'

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

    describe "RecordMode" do
      it "Should write response to file too" do
        Typhoeus.record_mode = Typhoeus::RECORD_MODE_RECORD
        @request.on_complete.clear
        @request.on_complete do |response|
          verify_response(response, @url)
          verify_recorded_file(@filename, @url)
        end
        @request.run

        # Do it again using Hydra
        remove_previous_record @request
        hydra = Typhoeus::Hydra.new
        hydra.queue @request
        hydra.run
        verify_recorded_file(@filename, @url)
      end
    end

    describe "ReplayMode" do
      it "Should replay response from file" do
        # First create a new record file
        @request.on_complete.clear
        Typhoeus.record_mode = Typhoeus::RECORD_MODE_RECORD
        @request.on_complete.clear
        @request.on_complete do |response|
          verify_response(response, @url)
          verify_recorded_file(@filename, @url)
        end
        @request.run

        # Calibrate record file to snafu url
        blob = File.read(@filename)
        blob = blob.gsub(/fubar/, 'snafu')
        File.write(@filename, blob)
        calibrated_url = 'http://snafu/'

        # Now in replay mode
        Typhoeus.record_mode = Typhoeus::RECORD_MODE_REPLAY
        @request.run
        @request.on_complete.clear
        @request.on_complete do |response|
          verify_response(response, calibrated_url)
        end

        # Do it again using Hydra
        hydra = Typhoeus::Hydra.new
        hydra.queue @request
        hydra.run
      end
    end
  end
end
