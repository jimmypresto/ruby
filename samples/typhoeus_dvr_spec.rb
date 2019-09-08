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
        @request.on_complete do |response|
          response.effective_url.must_equal @url
        end
        @request.run
        File.exist?(@filename).must_equal true
        File.read(@filename).include?(@url).must_equal true

        # Do it again using Hydra
        remove_previous_record @request
        hydra = Typhoeus::Hydra.new
        hydra.queue @request
        hydra.run
        File.exist?(@filename).must_equal true
        File.read(@filename).include?(@url).must_equal true
      end
    end

    describe "ReplayMode" do
      it "Should replay response from file" do
        @request.on_complete.clear
        Typhoeus.record_mode = Typhoeus::RECORD_MODE_RECORD
        @request.run
        File.exist?(@filename).must_equal true
        File.read(@filename).include?(@url).must_equal true

        # record file is not calibrated to snafu
        blob = File.read(@filename)
        blob = blob.gsub(/fubar/, 'snafu')
        File.write(@filename, blob)

        # Now in replay mode
        Typhoeus.record_mode = Typhoeus::RECORD_MODE_REPLAY
        @request.on_complete do |response|
          response.effective_url.must_equal 'http://snafu/'
        end
        @request.run

        # Do it again using Hydra
        hydra = Typhoeus::Hydra.new
        hydra.queue @request
        hydra.run
      end
    end
  end
end
