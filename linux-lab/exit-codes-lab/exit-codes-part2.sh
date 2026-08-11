#!/usr/bin/env bash

mkdir /tmp/my-app

if [ $? -eq 0 ]; then
    echo "Directory created"
else
    echo "Failed to create directory"
fi

echo "Continuing deployment..."
