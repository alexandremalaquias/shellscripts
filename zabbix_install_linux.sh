#!/bin/bash

source linux_os_version.sh


case $os_version in
    "Ubuntu 18.04" | "Ubuntu 20.04" | "Ubuntu 23.10")
        echo "Installing Zabbix Agent for Ubuntu"
        sudo apt update
        sudo apt install zabbix-agent -y
        ;;
    "CentOS" | "Fedora" | "Red Hat")
        echo "Installing Zabbix Agent for CentOS, Fedora, or Red Hat"
        sudo yum install zabbix-agent -y
        ;;
    "Debian")
        echo "Installing Zabbix Agent for Debian"
        sudo apt update
        sudo apt install zabbix-agent -y
        ;;
    *)
        echo "Unsupported OS: $os_version"
        ;;
esac
