#!/usr/bin/env bash

WALLPAPER="$1"

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
        --transition-duration 1 &

    MATUGEN_SOURCE="$WALLPAPER"

    # For lock screen, use the image directly
    cp "$WALLPAPER" /tmp/lock_bg.png 2>/dev/null
fi

# --- matugen: generate Material You colors from the wallpaper ---
if command -v matugen &>/dev/null; then
    matugen image "$MATUGEN_SOURCE" 2>/dev/null

    # Hot-reload all apps with new colors
    if [[ -x "$(command -v matugen-reload)" ]]; then
        matugen-reload &
    elif [[ -f "$HOME/.dotfiles/roles/bash/files/bash/scripts/matugen-reload.sh" ]]; then
        bash "$HOME/.dotfiles/roles/bash/files/bash/scripts/matugen-reload.sh" &
    fi
fi

wait
