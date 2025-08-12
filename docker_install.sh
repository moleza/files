#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- SCRIPT MUST BE RUN AS ROOT ---
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

echo "--- Starting Docker Installation for Ubuntu 24.04 ---"

# --- 1. Uninstall Old Versions (Best Practice) ---
echo "Removing any old Docker versions if they exist..."
# This loop will attempt to remove older packages and is safe to run even if none are installed.
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    apt-get remove -y $pkg >/dev/null 2>&1 || true
done


# --- 2. Set up Docker's Official Repository ---
echo "Setting up Docker's official repository..."
apt-get update
apt-get install -y ca-certificates curl

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
echo "Docker repository setup complete."


# --- 3. Install Docker Packages ---
echo "Installing Docker Engine, CLI, and plugins..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo "Docker installation complete."


# --- 4. Verify Installation ---
echo "Verifying Docker installation by running the hello-world container..."
# This command downloads a test image and runs it in a container.
# If the container runs, it prints a confirmation message and exits.
docker run hello-world


# --- 5. Post-installation Steps (Optional but Recommended) ---
echo ""
echo "----------------------------------------------------------------"
echo "✅ Docker has been successfully installed!"
echo ""
echo "To run Docker commands without needing 'sudo', you can add your user to the 'docker' group."
echo "Run the following command, replacing '\$USER' with your actual username:"
echo "   sudo usermod -aG docker \$USER"
echo ""
echo "IMPORTANT: You must log out and log back in for this group change to take effect."
echo "----------------------------------------------------------------"
