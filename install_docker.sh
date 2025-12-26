#!/bin/bash
# Don't use set -e immediately so we can handle errors logic
echo "Checking Docker status..."

# Function to check if docker is working
check_docker() {
    if command -v docker &> /dev/null; then
        if docker ps &> /dev/null; then
            return 0 # Working
        fi
    fi
    return 1 # Not working
}

if check_docker; then
    echo "Docker is already running and ready!"
    exit 0
fi

echo "Docker is not running or broken. Attempting to fix..."

# Try starting service if it exists roughly
if [ -f /lib/systemd/system/docker.service ] || [ -f /etc/init.d/docker ]; then
    echo "Docker service files detected. Trying to start..."
    sudo service docker start || echo "Start failed. Proceeding to reinstall..."
fi

if check_docker; then
    echo "Docker started successfully!"
    exit 0
fi

echo "Proceeding with full installation..."

# Update apt and install prereqs
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# Add Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
# Force overwrite key
if [ -f /etc/apt/keyrings/docker.gpg ]; then
    sudo rm /etc/apt/keyrings/docker.gpg
fi
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Repo
echo \
  "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker
echo "Starting Docker Service..."
sudo service docker start

# Add user to group
sudo usermod -aG docker $USER

echo "------------------------------------------------"
echo "Installation sequence finished."
echo "Please try running: docker ps"
echo "If it says 'permission denied', please restart your terminal or run: newgrp docker"
