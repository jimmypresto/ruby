FROM ruby:2.5-slim

RUN apt-get update \
    && apt-get install -y nginx \
    && apt-get install -y build-essential \
    && gem install bundler \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY Gemfile* ./
COPY nginx.conf ./
COPY start.sh ./
COPY app ./app
COPY config ./config
RUN bundle install

RUN chmod +x /usr/src/app/start.sh

EXPOSE 8080
CMD ["/usr/src/app/start.sh"]
