#!/usr/bin/env bash

set -euo pipefail

HOST="${1:-127.0.0.1}"
PORT="${2:-8080}"

echo "======================================"
echo " Connectivity Test"
echo "======================================"

echo "Host: $HOST"
echo "Port: $PORT"
echo

echo "---- ping ----"

if ping -c 3 "$HOST"; then
    echo "Ping: SUCCESS"
else
    echo "Ping: FAILED"
fi

echo
echo "---- TCP connection ----"

if nc -vz "$HOST" "$PORT"; then
    echo "TCP connection: SUCCESS"
else
    echo "TCP connection: FAILED"
fi

echo
echo "---- HTTP request ----"

if curl -fsS "http://${HOST}:${PORT}" >/dev/null; then
    echo "HTTP request: SUCCESS"
else
    echo "HTTP request: FAILED"
fi
