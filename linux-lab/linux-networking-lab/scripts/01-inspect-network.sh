#!/usr/bin/env bash

set -euo pipefail

echo "======================================"
echo " Linux Network Interfaces"
echo "======================================"

ip -br addr

echo
echo "======================================"
echo " Routing Table"
echo "======================================"

ip route

echo
echo "======================================"
echo " Listening TCP Sockets"
echo "======================================"

ss -lnt

echo
echo "======================================"
echo " Listening TCP Sockets + Processes"
echo "======================================"

ss -lntp
