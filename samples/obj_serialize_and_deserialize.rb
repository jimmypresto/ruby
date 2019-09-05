#!/usr/bin/env ruby -w

#require 'json'

#require 'marshal'
#require 'oj'
require 'typhoeus'

url = 'https://raw.githubusercontent.com/jimmypresto/perf/master/ffmpeg.txt'
response = Typhoeus.get(url)
#p response.class
#p response.inspect
hash = {}
response.instance_variables.each { |k| hash[k.to_s.delete("@")] = response.instance_variable_get(k) }

json_str = Marshal.dump response
#json_str = JSON.dump response
#json_str = response.inspect
#json_str = JSON.generate response
#json_str = Marshal.dump response
#json_str = Oj.dump(response, mode: :object, time_format: :xmlschema)
#p json_str.class
#p json_str.object_id
#p json_str.inspect
#p eval(json_str)

response2 = Marshal.load(json_str)
#response2 = JSON.parse(json_str, object_class: Typhoeus::Response)
#response2 = Marshal.load(json_str)
#response2 = Oj.load(json_str, mode: :object, time_format: :xmlschema)
#p response2.class
#p json_str.object_id
hash2 = {}
response2.instance_variables.each { |k| hash2[k.to_s.delete("@")] = response2.instance_variable_get(k) }

p "Do response and response2 have same effective_url? #{response.effective_url.eql? response2.effective_url}"
p "Do response and response2 have same return_code? #{response.return_code.eql? response2.return_code}"
p "Do response and response2 have same response_code? #{response.response_code.eql? response2.response_code}"
p "Do response and response2 have same response_headers? #{response.response_headers.eql? response2.response_headers}"
p "Do response and response2 have same response_body? #{response.response_body.eql? response2.response_body}"
p "Is response == response2? #{hash == hash2}"
