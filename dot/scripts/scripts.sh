#!/bin/bash

# Define script installation directory
SCRIPT_DIR="$HOME/.local/bin"

# Create directory if it doesn't exist
mkdir -p "$SCRIPT_DIR"

# Add script directory to PATH if not already present
if [[ ":$PATH:" != *":$SCRIPT_DIR:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "Added $SCRIPT_DIR to PATH in .bashrc"
    # Apply the change to current session
    export PATH="$SCRIPT_DIR:$PATH"
fi

# Function to install a script
install_script() {
    local script_name="$1"
    local script_path="$2"
    
    # Copy the script to the installation directory
    cp -f "$script_path" "$SCRIPT_DIR/$script_name"
    
    # Make it executable
    chmod +x "$SCRIPT_DIR/$script_name"
    
    echo "Installed $script_name"
}

# Install all scripts
echo "Installing custom scripts..."

# Wallpaper scripts
install_script "wall-change" "$HOME/.dotfiles/dot/scripts/scripts/wall-change.sh"
install_script "wallpaper-picker" "$HOME/.dotfiles/dot/scripts/scripts/wallpaper-picker.sh"
install_script "random-wallpaper" "$HOME/.dotfiles/dot/scripts/scripts/random-wallpaper.sh"

# Utility scripts
install_script "runbg" "$HOME/.dotfiles/dot/scripts/scripts/runbg.sh"

# Toggle scripts
install_script "toggle_blur" "$HOME/.dotfiles/dot/scripts/scripts/toggle_blur.sh"
install_script "toggle_oppacity" "$HOME/.dotfiles/dot/scripts/scripts/toggle_oppacity.sh"
install_script "toggle_waybar" "$HOME/.dotfiles/dot/scripts/scripts/toggle_waybar.sh"
install_script "toggle_float" "$HOME/.dotfiles/dot/scripts/scripts/toggle_float.sh"

# Archive management
install_script "compress" "$HOME/.dotfiles/dot/scripts/scripts/compress.sh"
install_script "extract" "$HOME/.dotfiles/dot/scripts/scripts/extract.sh"

# Help
install_script "show-keybinds" "$HOME/.dotfiles/dot/scripts/scripts/keybinds.sh"

# VM management
install_script "vm-start" "$HOME/.dotfiles/dot/scripts/scripts/vm-start.sh"

# Miscellaneous
install_script "ascii" "$HOME/.dotfiles/dot/scripts/scripts/ascii.sh"
install_script "record" "$HOME/.dotfiles/dot/scripts/scripts/record.sh"
install_script "screenshot" "$HOME/.dotfiles/dot/scripts/scripts/screenshot.sh"

# Power management
install_script "rofi-power-menu" "$HOME/.dotfiles/dot/scripts/scripts/rofi-power-menu.sh"
install_script "power-menu" "$HOME/.dotfiles/dot/scripts/scripts/power-menu.sh"
install_script "lg" "$HOME/.dotfiles/dot/scripts/scripts/lg.sh"

echo "All scripts have been installed to $SCRIPT_DIR"
echo "You may need to restart your terminal or run 'source ~/.bashrc' for the PATH changes to take effect"

source ~/.bashrc
