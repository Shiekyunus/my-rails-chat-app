FROM public.ecr.aws/docker/library/ruby:3.0.4-alpine

# ── System dependencies ────────────────────────────────────────────────────────
# gcompat: provides glibc compatibility shim for musl Alpine
# git: required by Bundler for gems sourced from git repos
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

# ── Bundler config BEFORE copying any files ────────────────────────────────────
# Must come before COPY so config is in place when Gemfile.lock is read.
# Disabling deployment mode lets Bundler modify the lockfile to add platforms.
RUN bundle config set --local deployment 'false' && \
    bundle config set --local without 'development test' && \
    bundle config build.mysql2 --with-mysql-config=/usr/bin/mysql_config

# ── Dependency files only (layer cache optimisation) ──────────────────────────
# Copying these separately means Docker reuses the bundle install cache
# on every build where only app code changed — not gem versions.
COPY Gemfile Gemfile.lock package.json yarn.lock ./

# ── THE CORE PLATFORM FIX ─────────────────────────────────────────────────────
# Your Gemfile.lock was generated on Windows (x64-mingw32).
# Alpine uses x86_64-linux-musl. Bundler checks the PLATFORMS section
# first and crashes immediately if the current platform isn't listed.
# --add-platform appends entries without touching any gem versions.
RUN bundle lock \
      --add-platform x86_64-linux \
      --add-platform x86_64-linux-musl

# ── Install gems & JS packages ────────────────────────────────────────────────
RUN bundle install --jobs 4 --retry 3

RUN yarn install --frozen-lockfile

# ── Application source ────────────────────────────────────────────────────────
# Copied AFTER gem/yarn install so that app-code changes don't invalidate
# the expensive bundle/yarn cache layers above.
COPY . .

RUN bundle config set --local deployment 'false'
# ── Environment ───────────────────────────────────────────────────────────────
ENV RAILS_ENV=production \
    NODE_ENV=production




# ── Asset precompilation ──────────────────────────────────────────────────────
# DATABASE_URL and credentials are dummies — Rails boot requires them
# to be set even though no real DB connection is made during compile.
# NODE_OPTIONS guards against JS heap exhaustion on large asset graphs.
# RUBYOPT=-rlogger surfaces Ruby-level errors that Rails silences by default.
#RUN DATABASE_URL=mysql2://dummy:dummy@localhost/dummy \
#    DATABASE_USER=dummy \
#    DATABASE_PASSWORD=dummy \
#    DATABASE_HOST=localhost \
#    DATABASE_NAME=dummy \
#    SECRET_KEY_BASE=75f6eb7e3aa4746833ac6785a3928123 \
#    NODE_OPTIONS="--max-old-space-size=4096" \
#    RUBYOPT="-rlogger" \
#    bundle exec rails assets:precompile

# ── Runtime ───────────────────────────────────────────────────────────────────
EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
