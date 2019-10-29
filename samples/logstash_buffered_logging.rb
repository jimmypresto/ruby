#!/bin/ruby -w

require 'logstash-logger'

logstash_outputs = [{ type: :file,
                      path: '/tmp/logstash_buffered_logging.log',
                      formatter: ::Logger::Formatter,
                      sync: false,
                      buffer_max_items: 10,
                      buffer_max_interval: 3,
                      drop_messages_on_flush_error: false,
                      drop_messages_on_full_buffer: false,
                      buffer_flush_at_exit: true,
                      error_logger: Logger.new(STDERR)
                   }]

logger = LogStashLogger.new(
  type: :multi_delegator,
  outputs: logstash_outputs
)

threads = Array.new
100.times { threads << Thread.new { logger.info "#{Thread.current.object_id}" } }
100.times { threads.pop.join }
sleep 2

100.times { threads << Thread.new { logger.info "#{Thread.current.object_id}" } }
100.times { threads.pop.join }
sleep 2
