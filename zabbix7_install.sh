#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- SCRIPT MUST BE RUN AS ROOT ---
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

echo "--- Starting Zabbix Agent 2 Installation for Ubuntu 24.04 ---"

# --- 1. Get Zabbix Server IP and Hostname from User ---
read -p "Please enter the IP address of your Zabbix server: " ZABBIX_SERVER_IP

# Check if an IP address was entered
if [ -z "$ZABBIX_SERVER_IP" ]; then
    echo "No Zabbix server IP entered. Exiting."
    exit 1
fi

read -p "Please enter the Hostname for this server (as it will appear in Zabbix): " ZABBIX_HOSTNAME

# Check if a hostname was entered
if [ -z "$ZABBIX_HOSTNAME" ]; then
    echo "No Hostname entered. Exiting."
    exit 1
fi


echo "Zabbix server will be set to: $ZABBIX_SERVER_IP"
echo "This server's hostname will be set to: $ZABBIX_HOSTNAME"

# --- 2. Install Zabbix Agent 2 ---
echo "Downloading Zabbix repository configuration package..."
# This command downloads the repository package for Zabbix 7.0 on Ubuntu 24.04 (Noble)
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-1+ubuntu24.04_all.deb

echo "Installing Zabbix repository..."
dpkg -i zabbix-release_7.0-1+ubuntu24.04_all.deb

echo "Updating package list..."
apt-get update

echo "Installing Zabbix agent 2..."
# Changed from zabbix-agent to zabbix-agent2
apt-get install -y zabbix-agent2

# Clean up the downloaded deb package
rm zabbix-release_7.0-1+ubuntu24.04_all.deb
echo "Zabbix agent 2 installed."

# --- 3. Configure Zabbix Agent 2 ---
echo "Configuring Zabbix agent 2..."
# Updated config file path for Zabbix Agent 2
ZABBIX_CONFIG="/etc/zabbix/zabbix_agent2.conf"

# Backup the original config file just in case
cp $ZABBIX_CONFIG "${ZABBIX_CONFIG}.bak"

# Use sed to replace the default Server, ServerActive, and Hostname with the user-provided values.
sed -i "s/Server=127.0.0.1/Server=$ZABBIX_SERVER_IP/g" $ZABBIX_CONFIG
sed -i "s/ServerActive=127.0.0.1/ServerActive=$ZABBIX_SERVER_IP/g" $ZABBIX_CONFIG
sed -i "s/Hostname=Zabbix server/Hostname=$ZABBIX_HOSTNAME/g" $ZABBIX_CONFIG

echo "Configuration file updated."

# --- 4. Open Firewall Port ---
echo "Adding firewall rule for Zabbix on eth1..."
# The Zabbix agent listens on port 10050. This rule restricts it to the eth1 interface.
ufw allow in on eth1 to any port 10050 proto tcp
echo "UFW rule added to allow traffic on TCP port 10050 from eth1."
ufw status | grep 10050

# --- 5. Restart and Enable Zabbix Agent 2 Service ---
echo "Restarting and enabling the Zabbix agent 2 service..."
# Updated service name to zabbix-agent2
systemctl restart zabbix-agent2
systemctl enable zabbix-agent2

systemctl is-active --quiet zabbix-agent2 && echo "Zabbix agent 2 is active and running." || echo "Zabbix agent 2 failed to start."

echo "--- Zabbix Agent 2 installation and configuration complete! ---"
