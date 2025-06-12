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
#set -e

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
sudo apt update && sudo apt install -y \
  python3-flake8-docstrings \
  python3-pip \
  python3-pytest-cov \
  ros-dev-tools \
  ros-jazzy-xacro

sudo apt install -y \
   python3-flake8-blind-except \
   python3-flake8-builtins \
   python3-flake8-class-newline \
   python3-flake8-comprehensions \
   python3-flake8-deprecated \
   python3-flake8-import-order \
   python3-flake8-quotes \
   python3-pytest-repeat \
   python3-pytest-rerunfailures
# Install ROS 2
# =============
echo "Updating package lists..."
sudo apt update

echo "Upgrading existing packages..."
sudo apt upgrade -y

echo "Installing ROS 2 Jazzy Jalisco Desktop..."
# manual Install : ROS, RViz, demos, tutorials.
sudo rm -rf /opt/ros/jazzy
sudo mkdir -p /opt/ros/jazzy/src
cd /opt/ros/jazzy
sudo vcs import --input https://raw.githubusercontent.com/ros2/ros2/jazzy/ros2.repos src

# Install deps using rosdep
sudo apt upgrade -y
sudo rosdep init
rosdep update
rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers" --os=ubuntu:noble --rosdistro=jazzy

cd /opt/ros/jazzy
colcon build --symlink-install

# Setup environment
# ================
echo "Setting up environment..."
# Add ROS2 setup to .bashrc for automatic sourcing in new terminals
if ! grep -q "source /opt/ros/jazzy/install/local_setup.bash" ~/.bashrc; then
    echo "# ROS2 Jazzy environment setup" >> ~/.bashrc
    echo "source /opt/ros/jazzy/install/local_setup.bash" >> ~/.bashrc
    echo "Added ROS2 setup to ~/.bashrc"
fi

# Source the setup file in the current session
source /opt/ros/jazzy/install/local_setup.bash

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
