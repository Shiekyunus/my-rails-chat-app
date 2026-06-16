# 1. Use the official AWS Public ECR mirror to completely bypass Docker Hub 429 rate limits
FROM public.ecr.aws/docker/library/ruby:3.0.4-alpine

# 2. Install essential system dependencies for building gems and database native extensions
RUN apk add --no-cache \
    build-base \
    mysql-client \
    mariadb-dev \
    nodejs \
    yarn \
    tzdata \
    gcompat \
    git

# Set the working directory inside the container
WORKDIR /app

# 3. Copy dependency locks first to leverage Docker caching layers
COPY Gemfile Gemfile.lock package.json yarn.lock ./

# Tell bundler where to find mysql config headers on Alpine Linux
RUN bundle config build.mysql2 --with-mysql-config=/usr/bin/mysql_config

# 4. Bulletproof Multi-Step Fix for the mysql2 dependency error
# Force add the Linux architecture, set local deployment mode, and execute the bundle build
RUN bundle lock --add-platform x86_64-linux x86_64-linux-musl
RUN bundle config set --local deployment 'true'
RUN bundle install

# Install javascript yarn dependencies
RUN yarn install --frozen-lockfile

# 5. Copy the rest of the chat application source code
COPY . .

# Set up compilation environment variables
ENV RAILS_ENV=production
ENV NODE_ENV=production

# 6. Precompile assets for production inside the build stage using dummy placeholders
RUN bundle lock --add-platform x86_64-linux x86_64-linux-musl && \
    DATABASE_URL=mysql2://dummy_user:dummy_pass@localhost/dummy_db \
    DATABASE_USER=dummy \
    DATABASE_PASSWORD=dummy \
    DATABASE_HOST=localhost \
    DATABASE_NAME=dummy \
    SECRET_KEY_BASE=75f6eb7e3aa4746833ac6785a3928123 \
    NODE_OPTIONS="--max-old-space-size=4096" \
    RUBYOPT="-rlogger" \
    bundle exec rails assets:precompile

# Expose the default app server port
EXPOSE 3000

# Start the application server
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
