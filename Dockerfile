ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION-slim-bookworm

ARG PG_VERSION=15
ARG MYSQL_VERSION=8.0
ARG NODE_VERSION=20
ARG BUNDLER_VERSION=2.9.15

RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    curl \
    git \
    imagemagick \
    libvips \
    libffi-dev \
    libmariadb-dev \
    sqlite3 \
    libsqlite3-dev \
    chromium \
    chromium-driver \
  && rm -rf /var/lib/apt/lists/*

# PostgreSQL repo
RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && echo "deb http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# MySQL repo
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B7B3B788A8D3785C \
 && echo "deb http://repo.mysql.com/apt/debian/ bookworm mysql-${MYSQL_VERSION}" > /etc/apt/sources.list.d/mysql.list

# NodeJS
RUN curl -sSL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash -

RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    libpq-dev \
    postgresql-client-$PG_VERSION \
    default-mysql-client \
    nodejs \
  && rm -rf /var/lib/apt/lists/*

ENV APP_USER=solidus_user \
    LANG=C.UTF-8 \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3
ENV GEM_HOME=/home/$APP_USER/gems
ENV APP_HOME=/home/$APP_USER/app
ENV PATH=$PATH:$GEM_HOME/bin

RUN useradd -ms /bin/bash $APP_USER
RUN gem update --system \
  && gem install bundler:$BUNDLER_VERSION \
  && chown -R $APP_USER:$(id -g $APP_USER) /home/$APP_USER/gems

USER $APP_USER
WORKDIR $APP_HOME

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY . .

RUN bundle exec rails db:prepare
RUN bundle exec rails assets:precompile || true

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "${PORT}"]
