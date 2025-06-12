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

# Gazebo
# If you have installed Gazebo, you may want to remove it as well.
echo "Removing Gazebo installation..."

# Remove Gazebo workspace
if [ -d ~/gazebo_ws ]; then
    echo "Deleting Gazebo workspace directory..."
    rm -rf ~/gazebo_ws
fi

# Remove Gazebo setup from .bashrc
if grep -q "source ~/gazebo_ws/install/setup.bash" ~/.bashrc; then
    echo "Removing Gazebo setup from .bashrc..."
    sed -i '/source ~\/gazebo_ws\/install\/setup.bash/d' ~/.bashrc
    sed -i '/# Gazebo environment setup/d' ~/.bashrc
    echo "Removed Gazebo setup from ~/.bashrc"
fi

# Remove Gazebo repository
echo "Removing Gazebo repository..."
if [ -f /etc/apt/sources.list.d/gazebo-stable.list ]; then
    sudo rm /etc/apt/sources.list.d/gazebo-stable.list
fi

# Remove Gazebo keyring
echo "Removing Gazebo keyring..."
if [ -f /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg ]; then
    sudo rm /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
fi

# Update package lists again after removing Gazebo repositories
sudo apt update

echo "Gazebo has been successfully uninstalled!"