#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- SCRIPT MUST BE RUN AS ROOT ---
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

echo "--- Starting MySQL 8 Installation and Secure Setup for Ubuntu 24.04 ---"

# --- 1. Update System Packages ---
echo "Updating package lists..."
apt-get update
echo "System update complete."

# --- 2. Install MySQL Server ---
# This will install the mysql-server package and its dependencies.
# The -y flag automatically answers 'yes' to any prompts.
echo "Installing MySQL Server..."
apt-get install -y mysql-server
echo "MySQL Server installation complete."

# --- 3. Secure MySQL Installation ---
# This is the most critical step. We will automate the 'mysql_secure_installation'
# script that ships with MySQL.

echo "Securing MySQL installation..."

# First, create a temporary file to hold the SQL commands.
# This is more secure than passing the password on the command line.
SECURE_MYSQL=$(mktemp)
cat > "$SECURE_MYSQL" <<EOF
-- Set a password for the root user.
-- IMPORTANT: Change 'YourStrongPassword' to a strong, unique password.
ALTER USER 'root'@'localhost' IDENTIFIED WITH 'caching_sha2_password' BY 'YourStrongPassword';
-- Remove anonymous users.
DELETE FROM mysql.user WHERE User='';
-- Disallow remote root login.
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- Remove the test database and access to it.
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- Reload the privilege tables to apply the changes.
FLUSH PRIVILEGES;
EOF

echo "Please replace 'YourStrongPassword' in the script with a real, strong password."
echo "You can edit the script now, or after running it, you can change the password by logging into MySQL and running:"
echo "ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';"
read -p "Press [Enter] to continue after you have acknowledged this message..."

# Run the SQL script using the default root user.
mysql < "$SECURE_MYSQL"

# Clean up the temporary file.
rm -f "$SECURE_MYSQL"

echo "MySQL installation has been secured."

# --- 4. Check MySQL Service Status ---
echo "Verifying MySQL service status..."
systemctl is-active --quiet mysql && echo "MySQL service is active and running." || echo "MySQL service failed to start."

echo "--- MySQL 8 installation and setup complete! ---"
