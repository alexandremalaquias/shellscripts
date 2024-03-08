#!/bin/bash

os_version=$(cat /etc/os-release | grep -oP '(?<=VERSION_ID=")\d+\.\d+' | head -1)

echo "Linux OS version: $os_version"

