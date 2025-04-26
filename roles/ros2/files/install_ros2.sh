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
sudo apt update && sudo apt install ros-dev-tools ros-jazzy-xacro -y

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


# installing gazebo from source
# ==========================

echo "Installing Gazebo from source..."
# Install Gazebo dependencies
sudo apt install python3-pip python3-venv lsb-release gnupg curl git -y

# vcstool and colcon from apt
sudo apt-get update
sudo apt-get install python3-vcstool python3-colcon-common-extensions -y

# make a workspace
mkdir -p ~/gazebo_ws/src
cd ~/gazebo_ws/src

# sources for gazebo
curl -O https://raw.githubusercontent.com/gazebo-tooling/gazebodistro/master/collection-harmonic.yaml
vcs import < collection-harmonic.yaml

# install dependencies
sudo curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable noble main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
sudo apt-get update

# The command below must be run from a workspace with the Gazebo source code and will install all dependencies in Ubuntu:
cd ~/gazebo_ws/src
sudo apt -y install $(sort -u $(find . -iname 'packages-'`lsb_release -cs`'.apt' -o -iname 'packages.apt' | grep -v '/\.git/') | sed '/gz\|sdf/d' | tr '\n' ' ')

# Build Gazebo
cd ~/gazebo_ws
# Build disabling tests
colcon build --cmake-args ' -DBUILD_TESTING=OFF' --merge-install

# add gazebo to bashrc for auto sourcing in new terminals
if ! grep -q "source ~/gazebo_ws/install/setup.bash" ~/.bashrc; then
    echo "# Gazebo environment setup" >> ~/.bashrc
    echo "source ~/gazebo_ws/install/setup.bash" >> ~/.bashrc
    echo "Added Gazebo setup to ~/.bashrc"
fi
# Source the setup file in the current session
source ~/gazebo_ws/install/setup.bash

echo "========================="
echo "Gazebo harmonic and ROS2 Jazzy Jalisco have been successfully installed!"
echo "========================="