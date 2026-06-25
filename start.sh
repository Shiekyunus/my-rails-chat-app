#!/bin/bash
set -e

mkdir -p /app/log

touch /app/log/production.log
touch /app/log/puma.log
touch /app/log/error.log

echo "Starting CloudWatch Agent..."
/opt/aws/amazon-cloudwatch-agent/bin/start-amazon-cloudwatch-agent &

echo "Starting Puma..."
exec bundle exec puma -C config/puma.rb
