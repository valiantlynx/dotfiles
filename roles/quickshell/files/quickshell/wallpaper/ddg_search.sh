#!/usr/bin/env bash
QUERY="$1"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
CACHE_DIR="$HOME/.cache/wallpaper_picker"
SEARCH_DIR="$CACHE_DIR/search_thumbs"
MAP_FILE="$CACHE_DIR/search_map.txt"
CONTROL_FILE="/tmp/ddg_search_control"
LOG_FILE="/tmp/qs_ddg_downloader.log"

echo "=== Starting search for: $QUERY ===" > "$LOG_FILE"

# 1. Guarantee directory exists (fixes silent curl failures)
mkdir -p "$SEARCH_DIR"

# 2. Use 'python3 -u' to force unbuffered output so the loop gets data INSTANTLY
python3 -u "$SCRIPT_DIR/get_ddg_links.py" "$QUERY" | while IFS='|' read -r thumb_url full_url; do
    
    # 3. Safely read control file, stripping weird invisible newlines
    state=$(cat "$CONTROL_FILE" 2>/dev/null | tr -d '[:space:]')
    
    if [[ "$state" == "stop" ]]; then 
        echo "Stop signal received. Exiting." >> "$LOG_FILE"
        exit 0 
    fi
    
    while [[ "$state" == "pause" ]]; do
        sleep 1
        state=$(cat "$CONTROL_FILE" 2>/dev/null | tr -d '[:space:]')
    done

    if [ -z "$thumb_url" ]; then continue; fi

    # Use a faster, safer unique ID generator
    uuid=$(date +%s%N)
    ext="${full_url##*.}"
    ext="${ext%%\?*}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    if [[ ! "$ext" =~ ^(jpg|jpeg|png|webp|gif)$ ]]; then ext="jpg"; fi

    # Force webp to jpg for Qt compatibility
    is_webp=0
    if [[ "$ext" == "webp" ]]; then
        is_webp=1
        ext="jpg"
    fi

    filename="ddg_${uuid}.${ext}"
    filepath="$SEARCH_DIR/$filename"
    tmppath="${filepath}.tmp"

    echo "Downloading: $thumb_url -> $filename" >> "$LOG_FILE"

    # Download to a temporary file first
    curl -s -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "$thumb_url" -o "$tmppath"

    # 4. Check state again AFTER the long curl block to prevent race conditions 
    # where the app tries to clear the directory while a download is still finishing.
    state=$(cat "$CONTROL_FILE" 2>/dev/null | tr -d '[:space:]')
    if [[ "$state" == "stop" ]]; then 
        echo "Stop signal received during download. Discarding." >> "$LOG_FILE"
        rm -f "$tmppath"
        exit 0 
    fi

    # If the file successfully downloaded and has data, atomically move it
    if [ -s "$tmppath" ]; then
        # Ensure WebP thumbnails are converted to JPG for QuickShell compatibility
        if file "$tmppath" | grep -iq "webp" || [ $is_webp -eq 1 ]; then
            magick "$tmppath" "$filepath" 2>/dev/null || mv "$tmppath" "$filepath"
            rm -f "$tmppath"
        else
            mv "$tmppath" "$filepath"
        fi
        echo "$filename|$full_url" >> "$MAP_FILE"
        echo "Success: $filename saved." >> "$LOG_FILE"
    else
        echo "ERROR: Failed or empty download for $thumb_url" >> "$LOG_FILE"
        rm -f "$tmppath"
    fi
done

echo "=== Pipeline finished ===" >> "$LOG_FILE"
