#!/usr/bin/env bash
# matugen_reload.sh — Hot-reload all apps after matugen generates new colors
# Called by wall-change.sh after matugen finishes

# --- Waybar ---
if pgrep -x "waybar" > /dev/null; then
    killall -SIGUSR2 waybar  # reload in-place
fi

# --- SwayNC ---
if pgrep -x "swaync" > /dev/null; then
    swaync-client --reload-css 2>/dev/null
fi

# --- SwayOSD ---
# SwayOSD reads CSS on each popup, so we just need to make sure
# the generated CSS is symlinked (handled by the CSS import chain)

# --- Hyprland ---
# Source the new border colors
if pgrep -x "Hyprland" > /dev/null; then
    hyprctl reload 2>/dev/null
fi

# --- Ghostty ---
# Ghostty auto-reloads config when the file changes, but only the main config.
# We signal it to re-read:
if pgrep -x "ghostty" > /dev/null; then
    # Ghostty watches its config file — touching it triggers reload
    touch ~/.config/ghostty/config 2>/dev/null
fi

# --- Vivaldi ---
# Update Vivaldi's active theme colors from matugen JSON
if [ -f /tmp/matugen-vivaldi-colors.json ]; then
    python3 ~/.config/bash/scripts/vivaldi-theme-update.py 2>/dev/null &
fi

# --- Cava ---
# Rebuild merged config and hot-reload
if pgrep -x "cava" > /dev/null; then
    if [ -f ~/.config/cava/config_base ] && [ -f ~/.config/cava/colors ]; then
        cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null
        killall -USR1 cava 2>/dev/null
    fi
fi

# --- tmux ---
# Source the new matugen colors into all running tmux sessions
if [ -f /tmp/matugen-tmux-colors.conf ] && command -v tmux &>/dev/null; then
    for session in $(tmux list-sessions -F '#S' 2>/dev/null); do
        tmux source-file /tmp/matugen-tmux-colors.conf 2>/dev/null
    done
fi

# --- Neovim ---
for server in $(find "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" -name "nvim*" -type s 2>/dev/null); do
    nvim --server "$server" --remote-send '<C-\><C-n>:lua if _G.reload_matugen_colors then _G.reload_matugen_colors() end<CR>' 2>/dev/null &
done

wait
