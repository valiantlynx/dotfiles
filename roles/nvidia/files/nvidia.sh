#!/bin/bash
script to work standalone

# NVIDIA packages to install
nvidia_pkg=(
  libva-wayland2
  libnvidia-egl-wayland1
  nvidia-vaapi-driver
  nvidia-driver-570-server
  nvidia-utils-570-server
)

# Create log directory if it doesn't exist
mkdir -p Install-Logs

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_nvidia.log"

# Color definitions for terminal output
YELLOW='\033[1;33m'
SKY_BLUE='\033[1;36m'
RESET='\033[0m'
ERROR='\033[1;31m'

# Function to install a package
install_package() {
  local package="$1"
  local log_file="$2"
  
  echo -e "${YELLOW}Installing ${SKY_BLUE}$package${RESET}..."
  if dpkg -l | grep -q "^ii  $package "; then
    echo -e "${SKY_BLUE}$package${RESET} is already installed."
  else
    sudo apt install -y "$package" 2>&1 | tee -a "$log_file"
    if [ $? -eq 0 ]; then
      echo -e "${SKY_BLUE}$package${RESET} installed successfully."
    else
      echo -e "${ERROR}Failed to install ${SKY_BLUE}$package${RESET}."
    fi
  fi
}

# Function to add a value to a configuration file if not present
add_to_file() {
  local config_file="$1"
  local value="$2"
  
  if ! sudo grep -q "$value" "$config_file"; then
    echo "Adding $value to $config_file"
    sudo sh -c "echo '$value' >> '$config_file'"
  else
    echo "$value is already present in $config_file."
  fi
}

# Update the package list
echo -e "${YELLOW}Updating package lists...${RESET}"
sudo apt update

#update drivers
sudo ubuntu-drivers autoinstall

# Install additional Nvidia packages
echo -e "${YELLOW}Installing ${SKY_BLUE}Nvidia packages${RESET}..."
for NVIDIA in "${nvidia_pkg[@]}"; do
  install_package "$NVIDIA" "$LOG"
done

# For Ubuntu users - uncomment the line below if you're using Ubuntu
# echo -e "${YELLOW}Installing recommended NVIDIA drivers for Ubuntu...${RESET}"
# sudo ubuntu-drivers install 2>&1 | tee -a "$LOG"

# Adding additional nvidia-stuff to GRUB
echo -e "${YELLOW}Adding ${SKY_BLUE}nvidia-stuff${RESET} to /etc/default/grub..."

# Additional options to add to GRUB_CMDLINE_LINUX
additional_options="rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1 rcutree.rcu_idle_gp_delay=1"

# Check if additional options are already present in GRUB_CMDLINE_LINUX
if grep -q "GRUB_CMDLINE_LINUX.*$additional_options" /etc/default/grub; then
  echo "GRUB_CMDLINE_LINUX already contains the additional options"
else
  # Append the additional options to GRUB_CMDLINE_LINUX
  sudo sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"$additional_options /" /etc/default/grub
  echo "Added the additional options to GRUB_CMDLINE_LINUX"
fi

# Update GRUB configuration
echo -e "${YELLOW}Updating GRUB configuration...${RESET}"
sudo update-grub 2>&1 | tee -a "$LOG"

# Define the configuration file and the line to add
config_file="/etc/modprobe.d/nvidia.conf"
line_to_add="options nvidia-drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1"

# Check if the config file exists
if [ ! -e "$config_file" ]; then
  echo "Creating $config_file"
  sudo touch "$config_file" 2>&1 | tee -a "$LOG"
fi
add_to_file "$config_file" "$line_to_add"

# Add NVIDIA modules to initramfs configuration
echo -e "${YELLOW}Adding NVIDIA modules to initramfs...${RESET}"
modules_to_add="nvidia
nvidia_modeset
nvidia_uvm
nvidia_drm"
modules_file="/etc/initramfs-tools/modules"
if [ -e "$modules_file" ]; then
  add_to_file "$modules_file" "$modules_to_add" 2>&1 | tee -a "$LOG"
  sudo update-initramfs -u 2>&1 | tee -a "$LOG"
else
  echo -e "${ERROR}Modules file ($modules_file) not found." 2>&1 | tee -a "$LOG"
fi

echo -e "${YELLOW}NVIDIA setup completed. A reboot is recommended.${RESET}"