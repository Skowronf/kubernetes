#!/usr/bin/env bash

echo "Running command..."

true

status=$?

echo "Exit status was: $status"

if [ "$status" -eq 0 ]; then
    echo "Command succeeded"
else
    echo "Command failed"
fi

exit "$status"
