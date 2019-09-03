FROM ruby:2.5-slim

RUN apt-get update \
    && apt-get install -y vim-tiny \
    && apt-get install -y less \
    && apt-get install -y nginx \
    && apt-get install -y build-essential \
    && gem install bundler \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY Gemfile* ./
COPY nginx.conf ./
COPY app ./app
COPY config ./config
RUN bundle install

EXPOSE 8080
CMD '/etc/init.d/nginx stop | nginx -c /user/src/app/nginx.conf || puma -C config/puma.rb'
