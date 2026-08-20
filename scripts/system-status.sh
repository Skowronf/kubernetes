#!/usr/bin/env bash
set -euo pipefail

CURRENT_USER=$(whoami)
CORE_NUMBER=$(nproc)
HOST_NAME=$(hostname)
LINUX_KERNEL=$(uname -r)
DATE=$(date)
OS=$(uname -o)
RAM=$(free -h | awk 'NR==2 {print $2}')

echo "working directory: $PWD"
echo "date: $DATE"
echo "linux kernel: $LINUX_KERNEL"
echo "operating system: $OS"
echo "host name: $HOST_NAME"
echo "current user: $CURRENT_USER"
echo "number of cores: $CORE_NUMBER"
echo "ram: $RAM"
