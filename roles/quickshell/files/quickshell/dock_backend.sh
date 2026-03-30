#!/usr/bin/env bash

STATE_FILE="$HOME/.cache/quickshell_dock_pinned.txt"
touch "$STATE_FILE"

if [ "$1" == "toggle" ]; then
    APP_NAME="$2"
    if grep -Fxq "$APP_NAME" "$STATE_FILE"; then
        grep -Fxv "$APP_NAME" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    else
        echo "$APP_NAME" >> "$STATE_FILE"
    fi
    exit 0
fi

if [ "$1" == "get" ]; then
    PATHS=(
        "/usr/share/applications"
        "/usr/local/share/applications"
        "$HOME/.local/share/applications"
        "/var/lib/flatpak/exports/share/applications"
        "/var/lib/snapd/desktop/applications"
    )

    find "${PATHS[@]}" -name "*.desktop" 2>/dev/null | while read -r file; do
        if grep -q "^NoDisplay=true" "$file"; then continue; fi
        
        name=$(grep -m 1 "^Name=" "$file" | cut -d '=' -f 2- | tr -d '|')
        icon=$(grep -m 1 "^Icon=" "$file" | cut -d '=' -f 2- | tr -d '|')
        exec=$(grep -m 1 "^Exec=" "$file" | cut -d '=' -f 2- | sed -E 's/ %.*//g' | tr -d '|')
        
        if [ -n "$name" ] && [ -n "$exec" ] && [ -n "$icon" ]; then
            pinned="false"
            if grep -Fxq "$name" "$STATE_FILE"; then pinned="true"; fi
            echo "${name}|${icon}|${exec}|${pinned}"
        fi
    done | awk '!seen[$1]++' FS="|" | jq -R -s -c '
        split("\n") | map(select(length > 0)) | map(split("|")) |
        map({name: .[0], icon: .[1], exec: .[2], pinned: (.[3] == "true")}) | sort_by(.name)
    '
fi
