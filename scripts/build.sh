#!/bin/bash

set -e
# Stops the script immediately if any command fails.

source ./scripts/env.sh

IMAGE="ghcr.io/skowronf/petclinic"
VERSION=$(git rev-parse --short HEAD)
# Gets the short version of the current Git commit hash.

echo "Building ${IMAGE}:${VERSION}"

mvn clean package -DskipTests

docker build \
  -t ${IMAGE}:${VERSION} .
# -t assigns a name and tag to the image:
# ghcr.io/Skowronf/petclinic:a81f4c9
# "." means Docker should use the Dockerfile
# from the current directory.


docker push \
  ${IMAGE}:${VERSION}
