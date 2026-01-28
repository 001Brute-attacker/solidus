FROM ruby:3.2.2

# System deps
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs \
  yarn

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENV RAILS_ENV=production
ENV RACK_ENV=production

RUN bundle exec rails assets:precompile || true

CMD bundle exec rails db:prepare && bundle exec rails server -b 0.0.0.0 -p $PORT
