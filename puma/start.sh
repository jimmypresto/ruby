#!/bin/bash -e

export PATH="/usr/sbin:/usr/local/bundle/bin/puma:$PATH"

/etc/init.d/nginx stop
nginx -c /usr/src/app/nginx.conf

puma -C config/puma.rb
