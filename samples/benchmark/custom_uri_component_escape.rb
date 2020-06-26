# gem install benchmark-ips
require "benchmark/ips"
require 'set'

URL_SAFE_CHAR_ARRAY = %w[* - _ . ; { } ,].append(*('0'..'9')).append(*('a'..'z')).append(*('A'..'Z')).freeze
URL_SAFE_CHAR_SET = URL_SAFE_CHAR_ARRAY.to_set.freeze
URL_SAFE_CHAR_STR = URL_SAFE_CHAR_ARRAY.join.freeze
URL_UNSAFE_CHAR_STR = *(0..255).reject { |c| URL_SAFE_CHAR_SET.include?(c.chr) }.join.freeze

def url_safe(user_data)
  return if user_data.nil?

  ret = StringIO.new
  user_data.to_s.each_char do |c|
    ret << if URL_SAFE_CHAR_SET.include?(c)
             c
           elsif c == ' '
             '+'
           else
             c.bytes.inject(StringIO.new) { |memo, b| memo << "%#{b.to_s(16).rjust(2, '0')}" }.string.upcase
           end
  end
  ret.string
end


Benchmark.ips do |x|
  x.report("all_unreserved_chars") { url_safe(URL_SAFE_CHAR_STR) }
  x.report("all_reserved_chars") { url_safe(URL_UNSAFE_CHAR_STR) }
end
