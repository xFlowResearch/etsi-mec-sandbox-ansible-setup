#!/bin/bash
set -e
echo "Updating package list..."
sudo apt update


echo "Stopping unattended-upgrades service..."
sudo systemctl stop unattended-upgrades



# echo "Installing software-properties-common..."
# sudo apt install -y software-properties-common

# echo "Adding Ansible PPA repository..."
# sudo add-apt-repository --yes --update ppa:ansible/ansible

# echo "Installing Ansible..."
# sudo apt install -y ansible

# echo "Verifying Ansible installation..."
# ansible --version

echo "Running Ansible playbook..."
ansible-playbook -i "127.0.0.1," -c local main.yml --ask-become-pass

echo "Restarting unattended-upgrades service..."
sudo systemctl start unattended-upgrades

source ~/.bashrc
source ~/.profile

echo "Done."
