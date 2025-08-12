#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- SCRIPT MUST BE RUN AS ROOT ---
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

echo "--- Starting Ubuntu 24.04 Initial Server Setup ---"

# --- 1. Update System ---
echo "Updating package lists and upgrading installed packages..."
apt-get update
apt-get upgrade -y
echo "System update complete."

# --- 2. Set Timezone ---
# Sets the system timezone.
# To see a list of available timezones, run: timedatectl list-timezones
echo "Setting timezone to Africa/Johannesburg..."
timedatectl set-timezone Africa/Johannesburg
echo "Timezone has been set."

# --- 3. Add New User ---
read -p "Please enter the username for the new user: " NEW_USERNAME

# Check if a username was entered
if [ -z "$NEW_USERNAME" ]; then
    echo "No username entered. Exiting."
    exit 1
fi

echo "Adding new user '$NEW_USERNAME'..."
if id "$NEW_USERNAME" &>/dev/null; then
    echo "User '$NEW_USERNAME' already exists. Skipping creation."
else
    # The --disabled-password flag means the user can't log in with a password
    # until one is set manually with 'sudo passwd <username>'.
    # The --gecos "" part avoids the interactive prompt for user information.
    adduser --disabled-password --gecos "" "$NEW_USERNAME"
    # Add the new user to the 'sudo' group to grant administrative privileges
    adduser "$NEW_USERNAME" sudo
    echo "User '$NEW_USERNAME' created and added to the sudo group."
    echo "IMPORTANT: Set a password for $NEW_USERNAME by running: sudo passwd $NEW_USERNAME"
fi

# --- 4. Configure Uncomplicated Firewall (UFW) ---
echo "Configuring the firewall..."
# Allow SSH connections. 'OpenSSH' is the profile name.
ufw allow OpenSSH
# Enable the firewall without an interactive prompt
ufw --force enable
echo "Firewall enabled and configured to allow SSH."
ufw status

# --- 5. Install and Enable Fail2ban for SSH Protection ---
echo "Installing Fail2ban to protect against SSH brute-force attacks..."
apt-get install -y fail2ban
# Fail2ban service starts automatically after installation and the default
# configuration protects SSH out of the box.
systemctl is-active --quiet fail2ban && echo "Fail2ban is active." || echo "Fail2ban failed to start."

# --- 6. Enable Automatic Security Updates ---
echo "Installing and enabling automatic security updates..."
apt-get install -y unattended-upgrades
# The default configuration is generally fine for most use cases.
# It enables automatic installation of security updates.
dpkg-reconfigure -plow unattended-upgrades
echo "Automatic security updates have been enabled."


echo "--- Initial setup complete! ---"

