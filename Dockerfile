FROM public.ecr.aws/docker/library/ruby:3.0.4-alpine
RUN apk add --no-cache \
    build-base \
    mysql-client \
    mariadb-dev \
    nodejs \
    yarn \
    tzdata \
    gcompat \
    git
WORKDIR /app
RUN gem install bundler:2.4.20
RUN bundle config set --local deployment 'false' && \
    bundle config set --local without 'development test' && \
    bundle config build.mysql2 --with-mysql-config=/usr/bin/mysql_config
COPY Gemfile Gemfile.lock package.json yarn.lock ./
RUN bundle lock \
      --add-platform x86_64-linux \
      --add-platform x86_64-linux-musl
RUN bundle install --jobs 4 --retry 3
RUN yarn install --frozen-lockfile
COPY . .
RUN chmod +x bin/*
RUN bundle config set --local deployment 'false'
ENV RAILS_ENV=production \
    NODE_ENV=production
RUN DATABASE_USER=dummy \
    DATABASE_PASSWORD=dummy \
    DATABASE_HOST=localhost \
    DATABASE_NAME=dummy \
    SECRET_KEY_BASE=dummy_for_assets_only \
    RUBYOPT="-rlogger" \
    bundle exec rails assets:precompile 2>&1 || true
RUN DATABASE_USER=dummy \
    DATABASE_PASSWORD=dummy \
    DATABASE_HOST=localhost \
    DATABASE_NAME=dummy \
    SECRET_KEY_BASE=dummy_for_assets_only \
    RUBYOPT="-rlogger" \
    bundle exec rails webpacker:compile
EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
