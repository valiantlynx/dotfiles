#!/usr/bin/env bash

# Wallpaper picker matugen reload - delegates to the main reload script
# plus handles quickshell-specific reloading
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:/opt/nvim-linux-x86_64/bin:$PATH"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

# Run the main matugen reload (waybar, swaync, hyprland, ghostty, tmux, nvim, etc.)
# Prefer the symlinked command on PATH, fall back to repo file, then deployed copy.
if command -v matugen-reload &>/dev/null; then
    matugen-reload
elif [ -f "$HOME/.dotfiles/roles/bash/files/bash/scripts/matugen-reload.sh" ]; then
    bash "$HOME/.dotfiles/roles/bash/files/bash/scripts/matugen-reload.sh"
elif [ -f "$HOME/.config/bash/scripts/matugen-reload.sh" ]; then
    bash "$HOME/.config/bash/scripts/matugen-reload.sh"
fi

wait
