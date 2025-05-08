#!/bin/bash
# hyprlock #

# Define color codes for better output
INFO="\e[1;36m[INFO]\e[0m"
OK="\e[1;32m[OK]\e[0m"
ERROR="\e[1;31m[ERROR]\e[0m"
YELLOW="\e[1;33m"
RESET="\e[0m"

# Dependencies
lock=(
    libpam0g-dev
    libgbm-dev
    libdrm-dev
    libmagic-dev
    libhyprlang-dev
    libhyprutils-dev
)

lock_tag="v0.4.0"  # Fallback version

# Create Install-Logs directory if it doesn't exist
mkdir -p Install-Logs

# Set the name of the log files
LOG="Install-Logs/install-$(date +%d-%H%M%S)_hyprlock.log"
MLOG="Install-Logs/install-$(date +%d-%H%M%S)_hyprlock2.log"

# Function to install or reinstall packages
re_install_package() {
    local package=$1
    local log_file=$2
    
    echo "${INFO} Installing/Reinstalling package: ${YELLOW}$package${RESET}"
    
    # Detect package manager
    if command -v apt &>/dev/null; then
        sudo apt install -y "$package" 2>&1 | tee -a "$log_file"
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm "$package" 2>&1 | tee -a "$log_file"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$package" 2>&1 | tee -a "$log_file"
    elif command -v zypper &>/dev/null; then
        sudo zypper install -y "$package" 2>&1 | tee -a "$log_file"
    else
        echo "${ERROR} No supported package manager found!" | tee -a "$log_file"
        return 1
    fi
    
    return 0
}

# Installation of dependencies
printf "\n%s - Installing ${YELLOW}hyprlock dependencies${RESET} .... \n" "${INFO}"
for PKG1 in "${lock[@]}"; do
    re_install_package "$PKG1" "$LOG"
done

# Check if hyprlock directory exists and remove it
if [ -d "hyprlock" ]; then
    rm -rf "hyprlock"
fi

# Clone and build hyprlock
printf "${INFO} Installing ${YELLOW}hyprlock $lock_tag${RESET} ...\n" | tee -a "$LOG"
if git clone --recursive -b "$lock_tag" https://github.com/hyprwm/hyprlock.git; then
    cd hyprlock || { 
        echo "${ERROR} Failed to change directory to hyprlock" | tee -a "$LOG"
        exit 1
    }
    
    # Build using cmake
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
    
    # Determine number of CPU cores for parallel build
    cores=$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)
    
    cmake --build ./build --config Release --target hyprlock -j"$cores"
    
    if sudo cmake --install build 2>&1 | tee -a "$MLOG"; then
        printf "${OK} ${YELLOW}hyprlock $lock_tag${RESET} installed successfully.\n" | tee -a "$MLOG"
    else
        echo -e "${ERROR} Installation failed for ${YELLOW}hyprlock $lock_tag${RESET}" | tee -a "$MLOG"
    fi
    
    cd ..
else
    echo -e "${ERROR} Download failed for ${YELLOW}hyprlock $lock_tag${RESET}" | tee -a "$LOG"
fi

printf "\n${OK} All operations completed.\n"
