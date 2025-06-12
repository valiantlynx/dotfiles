#!/bin/bash
# SWWW - Wallpaper Utility Standalone Installer

# Define color codes for output
RESET="\033[0m"
OK="\033[1;32m[OK]\033[0m"
NOTE="\033[1;36m[NOTE]\033[0m"
ERROR="\033[1;31m[ERROR]\033[0m"
MAGENTA="\033[1;35m"
YELLOW="\033[1;33m"
SKY_BLUE="\033[1;36m"

# Create logs directory if it doesn't exist
mkdir -p Install-Logs

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_swww.log"
MLOG="Install-Logs/install-$(date +%d-%H%M%S)_swww2.log"

# Function to install a package
install_package() {
    local package=$1
    local log_file=$2
    
    echo -e "${NOTE} Checking for ${YELLOW}$package${RESET}..."
    
    if command -v apt &>/dev/null; then
        # Debian/Ubuntu
        if ! dpkg -l | grep -q "^ii  $package "; then
            echo -e "${NOTE} Installing ${YELLOW}$package${RESET}..." | tee -a "$log_file"
            sudo apt install -y "$package" | tee -a "$log_file"
        else
            echo -e "${OK} ${YELLOW}$package${RESET} is already installed." | tee -a "$log_file"
        fi
    elif command -v pacman &>/dev/null; then
        # Arch
        if ! pacman -Q "$package" &>/dev/null; then
            echo -e "${NOTE} Installing ${YELLOW}$package${RESET}..." | tee -a "$log_file"
            sudo pacman -S --noconfirm "$package" | tee -a "$log_file"
        else
            echo -e "${OK} ${YELLOW}$package${RESET} is already installed." | tee -a "$log_file"
        fi
    elif command -v dnf &>/dev/null; then
        # Fedora
        if ! dnf list installed "$package" &>/dev/null; then
            echo -e "${NOTE} Installing ${YELLOW}$package${RESET}..." | tee -a "$log_file"
            sudo dnf install -y "$package" | tee -a "$log_file"
        else
            echo -e "${OK} ${YELLOW}$package${RESET} is already installed." | tee -a "$log_file"
        fi
    else
        echo -e "${ERROR} Unsupported package manager. Please install ${YELLOW}$package${RESET} manually." | tee -a "$log_file"
        return 1
    fi
}

# Check if 'swww' is installed
if command -v swww &>/dev/null; then
    SWWW_VERSION=$(swww -V | awk '{print $NF}')
    if [[ "$SWWW_VERSION" == "0.9.5" ]]; then
        echo -e "${OK} ${MAGENTA}swww v0.9.5${RESET} is already installed. Skipping installation."
        exit 0
    fi
else
    echo -e "${NOTE} ${MAGENTA}swww${RESET} is not installed. Proceeding with installation."
fi

# Dependencies
swww=(
    liblz4-dev
    git
    cargo
    build-essential
    pkg-config
)

# specific branch or release
swww_tag="v0.9.5"

# Installation of swww compilation dependencies
printf "\n%s - Installing ${SKY_BLUE}swww $swww_tag dependencies${RESET} .... \n" "${NOTE}"
for PKG1 in "${swww[@]}"; do
    install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..2}

# Set up temporary working directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR" || { echo -e "${ERROR} Failed to create temporary directory"; exit 1; }

# Check if swww directory exists
if [ -d "swww" ]; then
    cd swww || exit 1
    git pull origin main 2>&1 | tee -a "$MLOG"
else
    if git clone --recursive -b $swww_tag https://github.com/LGFae/swww.git; then
        cd swww || exit 1
    else
        echo -e "${ERROR} Download failed for ${YELLOW}swww $swww_tag${RESET}" 2>&1 | tee -a "$LOG"
        exit 1
    fi
fi

# Proceed with the rest of the installation steps
source "$HOME/.cargo/env" || true
cargo build --release 2>&1 | tee -a "$MLOG"

# Checking if swww is previously installed and delete before copying
file1="/usr/bin/swww"
file2="/usr/bin/swww-daemon"

# Check if file1 exists and delete if so
if [ -f "$file1" ]; then
    sudo rm -r "$file1"
fi

# Check if file2 exists and delete if so
if [ -f "$file2" ]; then
    sudo rm -r "$file2"
fi

# Copy binaries to /usr/bin/
sudo cp -r target/release/swww /usr/bin/ 2>&1 | tee -a "$MLOG"
sudo cp -r target/release/swww-daemon /usr/bin/ 2>&1 | tee -a "$MLOG"

# Copy bash completions
sudo mkdir -p /usr/share/bash-completion/completions 2>&1 | tee -a "$MLOG"
sudo cp -r completions/swww.bash /usr/share/bash-completion/completions/swww 2>&1 | tee -a "$MLOG"

# Copy zsh completions
sudo mkdir -p /usr/share/zsh/site-functions 2>&1 | tee -a "$MLOG"
sudo cp -r completions/_swww /usr/share/zsh/site-functions/_swww 2>&1 | tee -a "$MLOG"

# Clean up
cd - || exit 1
echo -e "${OK} ${MAGENTA}swww v0.9.5${RESET} has been successfully installed!"
printf "\n%.0s" {1..2}
