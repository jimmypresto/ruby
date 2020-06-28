# gem install benchmark-ips
require "benchmark/ips"
require 'set'
require 'uri'

URL_SAFE_CHAR_ARRAY = %w[* - _ . ; { } ,].append(*('0'..'9')).append(*('a'..'z')).append(*('A'..'Z')).freeze
URL_SAFE_CHAR_SET = URL_SAFE_CHAR_ARRAY.to_set.freeze
URL_SAFE_CHAR_STR = URL_SAFE_CHAR_ARRAY.join.freeze
URL_UNSAFE_CHAR_STR = *(0..255).reject { |c| URL_SAFE_CHAR_SET.include?(c.chr) }.join.freeze

Benchmark.ips do |x|
  x.report("all_unreserved_chars_URI.encode_www_form_component") { URI.encode_www_form_component(URL_SAFE_CHAR_STR) }
  x.report("all_reserved_chars_URI.encode_www_form_component") { URI.encode_www_form_component(URL_UNSAFE_CHAR_STR) }
end
