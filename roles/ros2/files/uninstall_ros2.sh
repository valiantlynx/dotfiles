#!/bin/bash

# ROS2 Jazzy Jalisco Uninstallation Script for Ubuntu 24.10
# =========================================================
#
# This script removes ROS2 Jazzy Jalisco from your Ubuntu system.

# Exit on error
set -e

echo "Uninstalling ROS 2 Jazzy Jalisco from Ubuntu 24.10"
echo "=================================================="

# Remove all ROS2 Jazzy packages
echo "Removing all ROS2 Jazzy packages..."
sudo apt remove ~nros-jazzy-* -y && sudo apt autoremove -y

# Remove the repository
echo "Removing the ROS2 repository..."
sudo rm /etc/apt/sources.list.d/ros2.list
sudo apt update
sudo apt autoremove -y

# Consider upgrading for packages previously shadowed
echo "Upgrading remaining packages..."
sudo apt upgrade -y

# Remove setup from .bashrc
echo "Removing ROS2 setup from .bashrc..."
if grep -q "source /opt/ros/jazzy/setup.bash" ~/.bashrc; then
    sed -i '/source \/opt\/ros\/jazzy\/setup.bash/d' ~/.bashrc
    sed -i '/# ROS2 Jazzy environment setup/d' ~/.bashrc
    echo "Removed ROS2 setup from ~/.bashrc"
fi

echo ""
echo "ROS 2 Jazzy Jalisco has been successfully uninstalled!"
echo ""