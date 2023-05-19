#!/bin/sh
set -x

echo "Parsing host and port..."
host=$(printf "%s\n" "$1"| cut -d : -f 1)
port=$(printf "%s\n" "$1"| cut -d : -f 2)

echo "Host: $host"
echo "Port: $port"

shift 1

while ! nc -z "$host" "$port"
do
  echo "Waiting for $host:$port"
  sleep 1
done

echo "Executing command: $@"
exec "$@"
