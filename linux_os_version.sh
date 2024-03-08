#!/bin/bash

# Check if the OS is Linux
if [[ "$(uname)" == "Linux" ]]; then
    # Check if the OS is Ubuntu
    if [[ -f "/etc/lsb-release" ]]; then
        source /etc/lsb-release
        os_version="Ubuntu $DISTRIB_RELEASE"
    # Check if the OS is CentOS
    elif [[ -f "/etc/centos-release" ]]; then
        os_version=$(cat /etc/centos-release)
    # Check if the OS is Fedora
    elif [[ -f "/etc/fedora-release" ]]; then
        os_version=$(cat /etc/fedora-release)
    # Check if the OS is Red Hat
    elif [[ -f "/etc/redhat-release" ]]; then
        os_version=$(cat /etc/redhat-release)
    # Check if the OS is Debian
    elif [[ -f "/etc/debian_version" ]]; then
        os_version=$(cat /etc/debian_version)
    else
        os_version="Unknown Linux distribution"
    fi
# Check if the OS is macOS
elif [[ "$(uname)" == "Darwin" ]]; then
    os_version=$(sw_vers -productVersion)
# Check if the OS is Windows
elif [[ "$(uname -o)" == "Msys" ]]; then
    os_version="Windows"
else
    os_version="Unknown operating system"
fi

echo "OS version: $os_version"
