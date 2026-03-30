#!/usr/bin/env bash

# Wallpaper picker matugen reload - delegates to the main reload script
# plus handles quickshell-specific reloading

# Run the main matugen reload (waybar, swaync, hyprland, ghostty, etc.)
if [ -x "$HOME/.config/bash/scripts/matugen-reload.sh" ]; then
    bash "$HOME/.config/bash/scripts/matugen-reload.sh"
fi

# Reload Neovim instances
for server in $(find "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" -name "nvim*" -type s 2>/dev/null); do
    nvim --server "$server" --remote-send '<C-\><C-n>:lua _G.reload_matugen_colors()<CR>' 2>/dev/null &
done

# Reload CAVA if running
if pgrep -x "cava" > /dev/null; then
    cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null
    killall -USR1 cava
fi

wait
