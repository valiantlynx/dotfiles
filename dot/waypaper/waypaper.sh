#!/bin/bash
# Waypaper Installer Script for Ubuntu 24.10
# This script installs Waypaper with all required dependencies

# Define color codes for output
RESET="\033[0m"
OK="\033[1;32m[OK]\033[0m"
NOTE="\033[1;36m[NOTE]\033[0m"
ERROR="\033[1;31m[ERROR]\033[0m"
MAGENTA="\033[1;35m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"

# Create logs directory if it doesn't exist
mkdir -p Install-Logs

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_waypaper.log"

echo -e "${NOTE} Starting Waypaper installation for Ubuntu 24.10..."

# Check if swww is installed
if ! command -v swww &>/dev/null; then
    echo -e "${ERROR} SWWW is not installed. Please install SWWW first."
    echo -e "You can use the SWWW installer script you already have."
    exit 1
else
    echo -e "${OK} ${GREEN}SWWW${RESET} is installed and will be used as the backend."
fi

# Install required dependencies
echo -e "${NOTE} Installing required dependencies..."

# List of dependencies for Waypaper on Ubuntu 24.10
dependencies=(
    python3-pip
    python3-venv
    python3-gi
    python3-cairo
    python3-gi-cairo
    gir1.2-gtk-3.0
    libgirepository1.0-dev
    libcairo2-dev
    pkg-config
    python3-dev
    pipx
    libgtk-3-dev
)

# Install dependencies
for dep in "${dependencies[@]}"; do
    echo -e "${NOTE} Installing ${YELLOW}$dep${RESET}..." | tee -a "$LOG"
    sudo apt install -y "$dep" | tee -a "$LOG"
done

# Ensure pipx path is available
export PATH="$PATH:$HOME/.local/bin"

# Install PyGObject using pip
echo -e "${NOTE} Installing ${YELLOW}PyGObject${RESET} using pip..."
pip3 install --user PyGObject | tee -a "$LOG"

# Install additional Python packages
echo -e "${NOTE} Installing additional Python packages..."
pip3 install --user imageio imageio-ffmpeg screeninfo platformdirs | tee -a "$LOG"

# Install Waypaper from source instead of using pipx
echo -e "${NOTE} Installing ${MAGENTA}Waypaper${RESET} from source..."

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Clone the repository
echo -e "${NOTE} Cloning the Waypaper repository..."
git clone https://github.com/anufrievroman/waypaper.git
cd waypaper

# Install using pip
echo -e "${NOTE} Installing Waypaper using pip..."
pip3 install --user . | tee -a "$LOG"

# Create a desktop entry for Waypaper
echo -e "${NOTE} Creating desktop entry for Waypaper..."
mkdir -p ~/.local/share/applications/

cat > ~/.local/share/applications/waypaper.desktop << EOF
[Desktop Entry]
Name=Waypaper
Comment=Wallpaper manager for Wayland
Exec=waypaper
Icon=preferences-desktop-wallpaper
Terminal=false
Type=Application
Categories=Utility;GTK;
Keywords=wallpaper;background;
EOF

# Create autostart entry to restore wallpaper on login
echo -e "${NOTE} Creating autostart entry to restore wallpaper on login..."
mkdir -p ~/.config/autostart/

cat > ~/.config/autostart/waypaper-restore.desktop << EOF
[Desktop Entry]
Name=Waypaper Restore
Comment=Restore wallpaper on login
Exec=waypaper --restore
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
EOF

# Create a default configuration directory if it doesn't exist
mkdir -p ~/.config/waypaper/

# Create a default configuration file if it doesn't exist
if [ ! -f ~/.config/waypaper/config.ini ]; then
    echo -e "${NOTE} Creating default configuration file..."
    cat > ~/.config/waypaper/config.ini << EOF
[Settings]
wallpaper = 
backend = swww
colorscheme = default
monitors = *
fill = fill
sort = name
language = en
EOF
fi

# Clean up
cd
rm -rf "$TEMP_DIR"

# Check if waypaper command is available
if command -v waypaper &>/dev/null; then
    echo -e "\n${OK} ${GREEN}Waypaper has been successfully installed!${RESET}"
    echo -e "\nYou can now run Waypaper by typing ${MAGENTA}waypaper${RESET} in the terminal or"
    echo -e "launching it from your application menu."
    echo -e "\nTo restore your wallpaper after system restart, the script has added"
    echo -e "${MAGENTA}waypaper --restore${RESET} to your autostart entries."
    echo -e "\nTo configure Waypaper, edit ${YELLOW}~/.config/waypaper/config.ini${RESET}"
else
    echo -e "\n${ERROR} Installation might have failed. Please try to run the following manually:"
    echo -e "pip3 install --user git+https://github.com/anufrievroman/waypaper.git"
fi
