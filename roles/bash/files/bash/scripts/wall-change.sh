#!/usr/bin/env bash

WALLPAPER="$1"

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wall-change"
LOCK_FILE="$CACHE_DIR/lock"
PID_FILE="$CACHE_DIR/pid"
RELOAD_SCRIPT="$HOME/.config/bash/scripts/matugen-reload.sh"

mkdir -p "$CACHE_DIR"

if [[ -f "$PID_FILE" ]]; then
    old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [[ -n "$old_pid" ]] && ! kill -0 "$old_pid" 2>/dev/null; then
        rm -f "$PID_FILE" "$LOCK_FILE"
    fi
fi

exec 9>"$LOCK_FILE"

# Ignore overlapping requests while a change is already in progress.
if ! flock -n 9; then
    exit 0
fi

printf '%s\n' "$$" >"$PID_FILE"

cleanup() {
    rm -f "$PID_FILE"
}

trap cleanup EXIT

# Do not let background children inherit the lock.
exec 9<&-

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "Usage: wall-change <path-to-image-or-video>"
    exit 1
fi

# --- Always kill mpvpaper first (avoid conflicts) ---
pkill mpvpaper 2>/dev/null || true

# --- Detect video vs image ---
EXT="${WALLPAPER##*.}"
IS_VIDEO=false
if [[ "${EXT,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
    IS_VIDEO=true
fi

if $IS_VIDEO; then
    # --- Video wallpaper via mpvpaper ---
    if command -v mpvpaper &>/dev/null; then
        mpvpaper -o 'loop --no-audio --hwdec=auto --profile=high-quality --video-sync=display-resample --interpolation --tscale=oversample' '*' "$WALLPAPER" &
    else
        echo "Error: mpvpaper not installed. Cannot set video wallpapers."
        exit 1
    fi

    # For matugen, extract a thumbnail frame to generate colors from
    THUMB="/tmp/wall-change-video-thumb.png"
    ffmpeg -y -ss 00:00:05 -i "$WALLPAPER" -vframes 1 -f image2 -q:v 2 "$THUMB" >/dev/null 2>&1
    MATUGEN_SOURCE="$THUMB"

    # For lock screen, use the thumbnail
    cp "$THUMB" /tmp/lock_bg.png 2>/dev/null
else
    # --- Image wallpaper via swww ---
    animations=("grow" "outer" "any" "wipe" "wave" "center")
    random_animation=${animations[RANDOM % ${#animations[@]}]}

    swww img "$WALLPAPER" \
        --transition-type="$random_animation" \
        --transition-pos 0.5,0.5 \
        --transition-fps 144 \
        --transition-duration 1

    MATUGEN_SOURCE="$WALLPAPER"

    # For lock screen, use the image directly
    cp "$WALLPAPER" /tmp/lock_bg.png 2>/dev/null
fi

# --- matugen: generate Material You colors from the wallpaper ---
# Run asynchronously so the wallpaper transition shows immediately.
if command -v matugen &>/dev/null; then
    (
        matugen image "$MATUGEN_SOURCE" 2>/dev/null

        # Hot-reload all apps with new colors
        if [[ -x "$RELOAD_SCRIPT" ]]; then
            bash "$RELOAD_SCRIPT"
        elif command -v matugen-reload >/dev/null 2>&1; then
            matugen-reload
        fi

        if command -v notify-send >/dev/null 2>&1; then
            notify-send "Theme updated"
        fi
    ) >/dev/null 2>&1 &
fi
