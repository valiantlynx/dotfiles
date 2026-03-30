#!/usr/bin/env bash
# Debug wrapper for wallpaper apply - logs everything
WALL_FILE="$1"
THUMB_FILE="$2"
RELOAD_SCRIPT="$3"
WALLPAPER_CMD="$4"
LOCK_BG_CMD="$5"

LOG="/tmp/wallpicker_debug.log"
echo "=== $(date) ===" >> "$LOG"
echo "WALL_FILE=$WALL_FILE" >> "$LOG"
echo "THUMB_FILE=$THUMB_FILE" >> "$LOG"
echo "RELOAD_SCRIPT=$RELOAD_SCRIPT" >> "$LOG"
echo "WALLPAPER_CMD=$WALLPAPER_CMD" >> "$LOG"
ls -la "$THUMB_FILE" >> "$LOG" 2>&1
ls -la "$WALL_FILE" >> "$LOG" 2>&1

# Set lock background
eval "$LOCK_BG_CMD" >> "$LOG" 2>&1

# Kill mpvpaper
pkill mpvpaper 2>/dev/null || true

# Set wallpaper
eval "$WALLPAPER_CMD" >> "$LOG" 2>&1 &

# Run matugen
echo "Running matugen on: $THUMB_FILE" >> "$LOG"
matugen image "$THUMB_FILE" >> "$LOG" 2>&1
MRC=$?
echo "matugen exit code: $MRC" >> "$LOG"

if [ $MRC -eq 0 ]; then
    echo "Running reload script: $RELOAD_SCRIPT" >> "$LOG"
    bash "$RELOAD_SCRIPT" >> "$LOG" 2>&1
    echo "reload exit code: $?" >> "$LOG"
else
    echo "MATUGEN FAILED with code $MRC" >> "$LOG"
fi

echo "=== done ===" >> "$LOG"
