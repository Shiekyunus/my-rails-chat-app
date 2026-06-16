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

# Copy dependency files
COPY Gemfile Gemfile.lock package.json yarn.lock ./

RUN bundle config build.mysql2 --with-mysql-config=/usr/bin/mysql_config

# Turn off deployment mode completely so bundler can fix the missing platforms dynamically
RUN bundle config set --local deployment 'false'
RUN bundle lock --add-platform x86_64-linux x86_64-linux-musl
RUN bundle install

RUN yarn install --frozen-lockfile

# Copy the rest of the application
COPY . .

ENV RAILS_ENV=production
ENV NODE_ENV=production

# Precompile assets for production using dummy placeholders
RUN DATABASE_URL=mysql2://dummy_user:dummy_pass@localhost/dummy_db \
    DATABASE_USER=dummy \
    DATABASE_PASSWORD=dummy \
    DATABASE_HOST=localhost \
    DATABASE_NAME=dummy \
    SECRET_KEY_BASE=75f6eb7e3aa4746833ac6785a3928123 \
    NODE_OPTIONS="--max-old-space-size=4096" \
    RUBYOPT="-rlogger" \
    bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
