#!/bin/bash

set -e
# Stops the script immediately if any command fails.

VERSION=$(git rev-parse --short HEAD)
# Gets the short Git commit hash of the current commit.

VALUES_FILE="charts/petclinic-platform/charts/petclinic/values.yaml"


sed -i \
"s/tag:.*/tag: ${VERSION}/" \
${VALUES_FILE}
# Updates the Docker image tag inside the Helm values file.
#
# sed:
#   A command-line text replacement tool.
#
# -i:
#   Modifies the file directly instead of only printing the result.
#
# "s/tag:.*/tag: ${VERSION}/":
#   Replaces any line starting with:
#
#       tag: something
#
#   with:
#
#       tag: <current-git-commit>