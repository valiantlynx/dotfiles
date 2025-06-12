#!/bin/bash
# hyprlock installation script

# Define color codes for better output
INFO="\e[1;36m[INFO]\e[0m"
OK="\e[1;32m[OK]\e[0m"
ERROR="\e[1;31m[ERROR]\e[0m"
YELLOW="\e[1;33m"
RESET="\e[0m"

# Enable error tracing
set -e

# Log file for debugging
LOG_FILE="/tmp/hyprlock_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting hyprlock installation script at $(date)" 

# Set version
lock_tag="v0.4.0"

# Create a working directory
WORK_DIR=$(pwd)
echo "Working directory: $WORK_DIR"

# Check if hyprlock directory exists and remove it if it does
if [ -d "hyprlock" ]; then
    echo "Removing existing hyprlock directory..."
    rm -rf hyprlock
fi

# Clone and build hyprlock
echo "${INFO} Installing ${YELLOW}hyprlock $lock_tag${RESET} ..."

echo "Cloning hyprlock repository..."
if ! git clone --recursive -b "$lock_tag" https://github.com/hyprwm/hyprlock.git; then
    echo "${ERROR} Failed to clone hyprlock repository"
    exit 1
fi

echo "Changing to hyprlock directory..."
cd hyprlock || { 
    echo "${ERROR} Failed to change directory to hyprlock"
    exit 1
}

echo "Running cmake configuration..."
if ! cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build; then
    echo "${ERROR} CMake configuration failed"
    exit 1
fi

# Determine number of CPU cores for parallel build
cores=$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)
echo "Building with $cores cores..."

if ! cmake --build ./build --config Release --target hyprlock -j"$cores"; then
    echo "${ERROR} CMake build failed"
    exit 1
fi

echo "Installing hyprlock..."
if ! sudo cmake --install build; then
    echo "${ERROR} Installation failed"
    exit 1
fi

# Check if hyprlock binary was actually installed
if [ -f "/usr/local/bin/hyprlock" ]; then
    echo "${OK} ${YELLOW}hyprlock $lock_tag${RESET} installed successfully."
else
    echo "${ERROR} Installation failed for ${YELLOW}hyprlock $lock_tag${RESET} - binary not found"
    exit 1
fi

cd "$WORK_DIR" || exit 1
echo "${OK} All operations completed."
echo "Installation completed at $(date)"
