#!/bin/bash

# ==============================================================================
# Create Application User Script
#
# Description:
# This script creates a new system user intended for running applications.
# It will interactively ask if the user should be granted permissions to
# manage Docker containers.
#
# The user will have a disabled password to prevent direct login and can be
# accessed via 'sudo su - <username>'.
#
# Usage:
#   1. Save this script as 'create_app_user.sh'.
#   2. Make it executable: chmod +x create_app_user.sh
#   3. Run with sudo and follow the prompts:
#      sudo ./create_app_user.sh
#
# ==============================================================================

# --- Configuration ---
readonly USERNAME="apprunner"
SETUP_DOCKER=false

# --- Pre-flight Checks ---

# Check if the script is being run as root.
if [[ "$(id -u)" -ne 0 ]]; then
   echo "Error: This script must be run as root or with sudo." >&2
   exit 1
fi

# --- Interactive Setup ---
# Ask the user if they want to configure Docker permissions.
read -p "Do you want to grant this user Docker permissions? (y/n) " -n 1 -r
echo # Move to a new line after input

if [[ $REPLY =~ ^[Yy]$ ]]; then
    SETUP_DOCKER=true
    echo "Info: Docker integration will be enabled."

    # If Docker setup is requested, check if the 'docker' group exists.
    if ! getent group docker >/dev/null; then
        echo "Error: Docker integration was requested, but the 'docker' group does not exist." >&2
        echo "Please install Docker before running this script with the Docker option." >&2
        exit 1
    fi
else
    echo "Info: Docker integration will be skipped."
fi


# Check if the user already exists to prevent errors.
if id "$USERNAME" &>/dev/null; then
    echo "Info: User '$USERNAME' already exists. No action taken."
    # Provide instructions on how to ensure the existing user is configured correctly.
    echo "To ensure the user has no password login, run: sudo passwd -l $USERNAME"
    if [[ "$SETUP_DOCKER" = true ]]; then
        echo "To ensure the user can manage Docker, run: sudo usermod -aG docker $USERNAME"
    fi
    exit 0
fi


# --- Main Execution ---

echo "Starting setup for user: $USERNAME"

# Step 1: Create the user account.
# --create-home: Creates a home directory for the user (/home/apprunner).
# --shell /bin/bash: Sets the user's default shell to bash.
echo "-> Creating user '$USERNAME' with a home directory..."
useradd --create-home --shell /bin/bash "$USERNAME"
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to create user '$USERNAME'." >&2
    exit 1
fi
echo "   ...User created successfully."


# Step 2: Lock the password for the new user.
# The -l flag locks the user's password, making it impossible to log in
# with a password. This is more secure than just assigning an empty password.
echo "-> Disabling password-based login for '$USERNAME'..."
passwd -l "$USERNAME" >/dev/null
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to lock the password for '$USERNAME'." >&2
    # Clean up by deleting the user if password lock fails.
    userdel -r "$USERNAME"
    exit 1
fi
echo "   ...Password locked successfully."


# Step 3: (Optional) Add the user to the 'docker' group.
if [[ "$SETUP_DOCKER" = true ]]; then
    # This grants the user the necessary permissions to interact with the
    # Docker daemon (e.g., run 'docker ps', 'docker build', 'docker-compose').
    # The -a (append) and -G (groups) flags add the user to the supplementary group.
    echo "-> Adding '$USERNAME' to the 'docker' group..."
    usermod -aG docker "$USERNAME"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to add '$USERNAME' to the 'docker' group." >&2
        exit 1
    fi
    echo "   ...User added to 'docker' group successfully."
fi


# --- Final Instructions ---

echo
echo "--------------------------------------------------"
echo "✅ Setup Complete!"
echo
echo "User '$USERNAME' has been created and configured."
echo
echo "To switch to this user, use the following command:"
echo "   sudo su - $USERNAME"
echo

if [[ "$SETUP_DOCKER" = true ]]; then
    echo "Once switched, you can verify Docker access by running:"
    echo "   docker ps"
fi
echo "--------------------------------------------------"

exit 0
