#!/bin/sh
set -x

echo "Waiting for database to be ready..."
db-wait.sh "$DB_HOST:$DB_PORT"

echo "Creating database..."
bundle exec rails db:create

echo "Running migrations..."
bundle exec rails db:migrate

if [ "$FCREPO_HOST" ]; then
  echo "Waiting for FCREPO to be ready..."
  db-wait.sh "$FCREPO_HOST:$FCREPO_PORT"
fi

echo "Waiting for SOLR to be ready..."
db-wait.sh "$SOLR_HOST:$SOLR_PORT"

echo "Seeding database..."
bundle exec rails db:seed
