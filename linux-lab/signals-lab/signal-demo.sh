#!/bin/bash
#trap can be used to catch signals and execute commands when those signals are received. 
#In this example, we will catch the SIGTERM signal and perform some cleanup before exiting.
trap 'echo "Received SIGTERM"; echo "Cleaning up..."; sleep 2; echo "Exiting"; exit 0' TERM

echo "Process started. PID=$$"

while true; do
    sleep 1
done
EOF