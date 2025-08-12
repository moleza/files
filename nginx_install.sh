#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- SCRIPT MUST BE RUN AS ROOT ---
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

echo "--- Starting Nginx and Certbot Installation for Ubuntu 24.04 ---"

# --- 1. Update System Packages ---
echo "Updating package lists..."
apt-get update
echo "System update complete."

# --- 2. Install Nginx ---
echo "Installing Nginx web server..."
apt-get install -y nginx
echo "Nginx installation complete."

# --- 3. Apply Nginx Best Practices ---
echo "Applying Nginx hardening and performance best practices..."

# Set worker_processes to auto to match the number of CPU cores
sed -i 's/worker_processes .*/worker_processes auto;/' /etc/nginx/nginx.conf

# Create a new config file for security hardening to avoid modifying the main nginx.conf
cat > /etc/nginx/conf.d/90-hardening.conf <<EOF
# Disables server version information from being broadcast.
server_tokens off;

# Defines a rate-limiting zone to protect against brute-force attacks.
# This is NOT applied globally. You must enable it in a specific server or location block.
# Example: limit_req zone=default_limit;
limit_req_zone \$binary_remote_addr zone=default_limit:10m rate=10r/s;
EOF

echo "Best practices applied."

# --- 4. Adjust Firewall ---
echo "Configuring firewall to allow Nginx traffic..."
# 'Nginx Full' profile allows both HTTP (port 80) and HTTPS (port 443) traffic.
ufw allow 'Nginx Full'
echo "Firewall updated."
ufw status | grep "Nginx Full"

# --- 5. Install Certbot ---
echo "Installing Certbot and the Nginx plugin..."
# On Ubuntu 24.04, Certbot is available directly from the system repositories.
apt-get install -y certbot python3-certbot-nginx
echo "Certbot installation complete."

# --- 6. Final Instructions ---
echo ""
echo "----------------------------------------------------------------"
echo "✅ Nginx and Certbot have been successfully installed!"
echo ""
echo "To obtain an SSL certificate, you must have a domain name pointing to this server's public IP."
echo "Once your DNS is configured, run the following command:"
echo ""
echo "   sudo certbot --nginx -d your_domain.com -d www.your_domain.com"
echo ""
echo "Replace 'your_domain.com' with your actual domain name."
echo "Certbot will automatically edit your Nginx configuration to set up HTTPS."
echo ""
echo "NOTE: A default rate-limiting zone has been created. To protect a specific location (like a login page),"
echo "add 'limit_req zone=default_limit;' inside that location block in your Nginx config."
echo "----------------------------------------------------------------"
