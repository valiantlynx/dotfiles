#!/usr/bin/env bash
# matugen_reload.sh — Hot-reload all apps after matugen generates new colors
# Called by wall-change.sh after matugen finishes

# Ensure nvim and other tools are on PATH (quickshell/hyprland may not source .bashrc)
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:/opt/nvim-linux-x86_64/bin:$PATH"

# Ensure session bus is available (quickshell may not inherit these)
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

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
# Ghostty does NOT hot-reload palette/background colors from config changes.
# Instead we use Ghostty's OSC 5577 escape sequence to push color changes
# directly to all running terminal sessions, AND update the config file
# (so new windows/restarts get the right colors).
if pgrep -x "ghostty" > /dev/null; then
    GHOSTTY_CONF="$HOME/.config/ghostty/config"
    MATUGEN_COLORS="/tmp/matugen-ghostty-colors.conf"
    if [ -f "$MATUGEN_COLORS" ]; then
        # 1) Update config file for persistence (new windows, restarts)
        if [ -f "$GHOSTTY_CONF" ] && grep -q "MATUGEN_START" "$GHOSTTY_CONF"; then
            python3 -c "
conf = '$GHOSTTY_CONF'
colors = '$MATUGEN_COLORS'
with open(conf, 'r') as f:
    lines = f.readlines()
with open(colors, 'r') as f:
    color_lines = [l for l in f.readlines() if l.strip() and not l.startswith('#')]
new = []
skip = False
for line in lines:
    if '--- MATUGEN_START ---' in line:
        new.append('# --- MATUGEN_START ---\n')
        new.append('# Dynamic Material You colors (spliced by matugen-reload.sh)\n')
        for cl in color_lines:
            new.append(cl)
        skip = True
        continue
    if '--- MATUGEN_END ---' in line:
        new.append('# --- MATUGEN_END ---\n')
        skip = False
        continue
    if not skip:
        new.append(line)
with open(conf, 'w') as f:
    f.writelines(new)
" 2>/dev/null
        fi
        # 2) Trigger Ghostty to reload config via DBus
        gdbus call --session \
            --dest com.mitchellh.ghostty \
            --object-path /com/mitchellh/ghostty \
            --method org.gtk.Actions.Activate \
            "reload-config" "[]" "{}" 2>/dev/null
    fi
fi

# --- Vivaldi ---
# Update Vivaldi's active theme colors from matugen JSON
if [ -f /tmp/matugen-vivaldi-colors.json ]; then
    python3 ~/.config/bash/scripts/vivaldi-theme-update.py 2>/dev/null &
fi

# --- Cava ---
# Always rebuild merged config so it's fresh when cava launches.
# Send SIGUSR1 to hot-reload if cava is already running.
if [ -f ~/.config/cava/config_base ] && [ -f ~/.config/cava/colors ]; then
    cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null
    if pgrep -x "cava" > /dev/null; then
        killall -USR1 cava 2>/dev/null
    fi
fi

# --- tmux ---
# Source the new matugen colors into all running tmux sessions.
# Note: pgrep -x "tmux" won't match "tmux: server" — use tmux list-sessions instead.
if [ -f /tmp/matugen-tmux-colors.conf ] && command -v tmux &>/dev/null; then
    if tmux list-sessions &>/dev/null; then
        tmux source-file /tmp/matugen-tmux-colors.conf 2>/dev/null
    fi
fi

# --- OpenCode ---
# OpenCode theme is written directly to ~/.config/opencode/themes/matugen.json
# by matugen. No hot-reload needed — new sessions pick up the updated theme
# automatically, and the TUI reads the theme file on startup.

# --- Neovim ---
# Use --remote-expr with luaeval for reliable reload regardless of current editor mode.
# --remote-send with <C-\><C-n>: can fail if nvim is in certain states (insert, cmdline, etc.).
for server in $(find "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" -name "nvim*" -type s 2>/dev/null); do
    nvim --server "$server" --remote-expr 'luaeval("_G.reload_matugen_colors()")' 2>/dev/null &
done

wait
