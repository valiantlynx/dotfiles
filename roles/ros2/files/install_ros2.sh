#!/bin/bash

# ROS2 Jazzy Jalisco Installation Script for Ubuntu 24.10
# ======================================================
#
# Deb packages for ROS 2 Jazzy Jalisco are currently available for Ubuntu Noble (24.04).
# The target platforms are defined in REP 2000.
#
# Resources:
# - Status Page: ROS 2 Jazzy (Ubuntu Noble 24.04): amd64, arm64
# - Jenkins Instance
# - Repositories

# Exit on error
set -e

echo "Installing ROS 2 Jazzy Jalisco on Ubuntu 24.10"
echo "=============================================="

# Set locale
# ==========
# Make sure you have a locale which supports UTF-8. If you are in a minimal environment
# (such as a docker container), the locale may be something minimal like POSIX.
echo "Setting up locale..."
locale  # check for UTF-8
sudo apt update && sudo apt install locales -y
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
locale  # verify settings

# Enable required repositories
# ===========================
echo "Enabling required repositories..."
# First ensure that the Ubuntu Universe repository is enabled.
sudo apt install software-properties-common -y
sudo add-apt-repository universe -y

# Now add the ROS 2 GPG key with apt.
sudo apt update && sudo apt install curl -y
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# Then add the repository to your sources list.
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu noble main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Install development tools (optional)
# ===================================
echo "Installing development tools..."
sudo apt update && sudo apt install ros-dev-tools -y

# Install ROS 2
# =============
echo "Updating package lists..."
sudo apt update

echo "Upgrading existing packages..."
sudo apt upgrade -y

echo "Installing ROS 2 Jazzy Jalisco Desktop..."
# Desktop Install (Recommended): ROS, RViz, demos, tutorials.
sudo apt install ros-jazzy-desktop -y

# You can uncomment the following line if you prefer the minimal installation
# ROS-Base Install (Bare Bones): Communication libraries, message packages, command line tools. No GUI tools.
# sudo apt install ros-jazzy-ros-base -y

# Install additional RMW implementations (optional)
# ================================================
# The default middleware that ROS 2 uses is Fast DDS, but the middleware (RMW)
# can be replaced at runtime. See the guide(https://docs.ros.org/en/jazzy/How-To-Guides/Working-with-multiple-RMW-implementations.html) on how to work with multiple RMWs.

# Setup environment
# ================
echo "Setting up environment..."
# Add ROS2 setup to .bashrc for automatic sourcing in new terminals
if ! grep -q "source /opt/ros/jazzy/setup.bash" ~/.bashrc; then
    echo "# ROS2 Jazzy environment setup" >> ~/.bashrc
    echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
    echo "Added ROS2 setup to ~/.bashrc"
fi

# Source the setup file in the current session
source /opt/ros/jazzy/setup.bash

echo ""
echo "ROS 2 Jazzy Jalisco has been successfully installed!"
echo ""
echo "Try some examples:"
echo "In one terminal run: ros2 run demo_nodes_cpp talker"
echo "In another terminal run: ros2 run demo_nodes_py listener"
echo ""
echo "Next steps:"
echo "- Continue with the tutorials and demos to configure your environment"
echo "- Create your own workspace and packages"
echo "- Learn ROS 2 core concepts"
echo ""
echo "For troubleshooting techniques visit the ROS 2 wiki."