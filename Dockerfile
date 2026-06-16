FROM public.ecr.aws/docker/library/ruby:3.0.4-alpine

# Install essential system dependencies for building gems and compilation
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

# Copy dependency locks first to leverage Docker caching
COPY Gemfile Gemfile.lock package.json yarn.lock ./

# Tell bundler where to find mysql config headers on Alpine
RUN bundle config build.mysql2 --with-mysql-config=/usr/bin/mysql_config

# Install application dependencies
RUN bundle install
RUN yarn install --frozen-lockfile

# Copy the rest of the chat application code
COPY . .

# Precompile assets for production inside the build stage
ENV RAILS_ENV=production
ENV NODE_ENV=production

# Provide fake dummy placeholders so Rails doesn't crash during the asset build phase
RUN DATABASE_URL=mysql2://dummy_user:dummy_pass@localhost/dummy_db \
    DATABASE_USER=dummy \
    DATABASE_PASSWORD=dummy \
    DATABASE_HOST=localhost \
    DATABASE_NAME=dummy \
    SECRET_KEY_BASE=75f6eb7e3aa4746833ac6785a3928123 \
NODE_OPTIONS="--max-old-space-size=4096" \
    RUBYOPT="-rlogger" \
    bundle exec rails assets:precompile

# Expose the standard Rails port (and WebSocket channel port)
EXPOSE 3000

# Clear any lingering server process IDs on boot and launch the Rails server
CMD ["sh", "-c", "rm -f tmp/pids/server.pid && bundle exec rails server -b '0.0.0.0'"]
