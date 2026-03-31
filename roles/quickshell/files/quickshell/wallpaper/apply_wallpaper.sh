#!/usr/bin/env bash
# Wallpaper apply script - handles both images (swww) and videos (mpvpaper)
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:/opt/nvim-linux-x86_64/bin:$PATH"

WALL_FILE="$1"
THUMB_FILE="$2"
RELOAD_SCRIPT="$3"
TRANSITION="$4"

LOG="/tmp/wallpicker_debug.log"
echo "=== $(date) ===" >> "$LOG"
echo "WALL_FILE=$WALL_FILE" >> "$LOG"
echo "THUMB_FILE=$THUMB_FILE" >> "$LOG"
echo "RELOAD_SCRIPT=$RELOAD_SCRIPT" >> "$LOG"
echo "TRANSITION=$TRANSITION" >> "$LOG"
ls -la "$THUMB_FILE" >> "$LOG" 2>&1
ls -la "$WALL_FILE" >> "$LOG" 2>&1

# Kill mpvpaper (always, whether switching to image or video)
pkill mpvpaper 2>/dev/null || true

# Detect video by extension
case "${WALL_FILE,,}" in
    *.mp4|*.mkv|*.webm|*.avi|*.mov|*.wmv|*.flv)
        IS_VIDEO=1
        ;;
    *)
        IS_VIDEO=0
        ;;
esac

# Set lock screen background
if [ "$IS_VIDEO" -eq 1 ]; then
    cp "$THUMB_FILE" /tmp/lock_bg.png >> "$LOG" 2>&1
else
    cp "$WALL_FILE" /tmp/lock_bg.png >> "$LOG" 2>&1
fi

# Set wallpaper
if [ "$IS_VIDEO" -eq 1 ]; then
    echo "Setting video wallpaper with mpvpaper" >> "$LOG"
    # Clear swww so it doesn't cover the video wallpaper
    swww clear 000000 >> "$LOG" 2>&1
    mpvpaper -o 'loop --no-audio --hwdec=auto --profile=high-quality --video-sync=display-resample --interpolation --tscale=oversample' '*' "$WALL_FILE" >> "$LOG" 2>&1 &
else
    echo "Setting image wallpaper with swww (transition: ${TRANSITION:-random})" >> "$LOG"
    swww img "$WALL_FILE" --transition-type "${TRANSITION:-random}" --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> "$LOG" 2>&1 &
fi

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
