FROM public.ecr.aws/docker/library/ruby:3.0.4

RUN apt-get update && apt-get install -y \
    build-essential \
    default-mysql-client \
    default-libmysqlclient-dev \
    tzdata \
    git \
    curl \
    unzip \
    gnupg \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

RUN npm install -g yarn
RUN node -v && npm -v && yarn -v

# Install CloudWatch Agent (official installer works on Debian)
RUN curl -O https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb && \
    dpkg -i amazon-cloudwatch-agent.deb && \
    rm -f amazon-cloudwatch-agent.deb

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
RUN yarn install
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

RUN mkdir -p /app/log && \
    touch /app/log/production.log && \
    touch /app/log/puma.log && \
    touch /app/log/error.log

COPY cloudwatch-agent-config.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
COPY supervisord.conf /etc/supervisord.conf

EXPOSE 3000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
