#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- SCRIPT MUST BE RUN AS ROOT ---
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

echo "--- Starting Zabbix Agent Installation for Ubuntu 24.04 ---"

# --- 1. Get Zabbix Server IP from User ---
read -p "Please enter the IP address of your Zabbix server: " ZABBIX_SERVER_IP

# Check if an IP address was entered
if [ -z "$ZABBIX_SERVER_IP" ]; then
    echo "No Zabbix server IP entered. Exiting."
    exit 1
fi

echo "Zabbix server will be set to: $ZABBIX_SERVER_IP"

# --- 2. Install Zabbix Agent ---
echo "Downloading Zabbix repository configuration package..."
# This command downloads the repository package for Zabbix 7.0 on Ubuntu 24.04 (Noble)
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-1+ubuntu24.04_all.deb

echo "Installing Zabbix repository..."
dpkg -i zabbix-release_7.0-1+ubuntu24.04_all.deb

echo "Updating package list..."
apt-get update

echo "Installing Zabbix agent..."
apt-get install -y zabbix-agent

# Clean up the downloaded deb package
rm zabbix-release_7.0-1+ubuntu24.04_all.deb
echo "Zabbix agent installed."

# --- 3. Configure Zabbix Agent ---
echo "Configuring Zabbix agent..."
ZABBIX_CONFIG="/etc/zabbix/zabbix_agentd.conf"

# Backup the original config file just in case
cp $ZABBIX_CONFIG "${ZABBIX_CONFIG}.bak"

# Use sed to replace the default Server and ServerActive IPs with the user-provided one.
# The `s` command is for substitute. The `g` flag means global (replace all occurrences on a line).
sed -i "s/Server=127.0.0.1/Server=$ZABBIX_SERVER_IP/g" $ZABBIX_CONFIG
sed -i "s/ServerActive=127.0.0.1/ServerActive=$ZABBIX_SERVER_IP/g" $ZABBIX_CONFIG

echo "Configuration file updated."

# --- 4. Open Firewall Port ---
echo "Adding firewall rule for Zabbix..."
# The Zabbix agent listens on port 10050 for connections from the server.
ufw allow 10050/tcp
echo "UFW rule added to allow traffic on TCP port 10050."
ufw status | grep 10050

# --- 5. Restart and Enable Zabbix Agent Service ---
echo "Restarting and enabling the Zabbix agent service..."
systemctl restart zabbix-agent
systemctl enable zabbix-agent

systemctl is-active --quiet zabbix-agent && echo "Zabbix agent is active and running." || echo "Zabbix agent failed to start."

echo "--- Zabbix Agent installation and configuration complete! ---"
