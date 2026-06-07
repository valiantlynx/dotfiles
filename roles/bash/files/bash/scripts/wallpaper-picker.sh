#!/usr/bin/env bash

set -euo pipefail

wallpapers_folder="$HOME/.dotfiles/shell-wallpapers"
current_wallpaper_name="$(basename "$(readlink "$HOME/.dotfiles/roles/bash/files/wallpapers/wallpaper" 2>/dev/null || true)")"
selected_index=0

wallpaper_name="$(
    i=0
    for path in "$wallpapers_folder"/*; do
        [ -f "$path" ] || continue
        name="$(basename "$path")"
        if [[ "$name" == "$current_wallpaper_name" ]]; then
            selected_index=$i
        fi
        printf '%s\0icon\x1f%s\n' "$name" "$path"
        i=$((i + 1))
    done | rofi -dmenu \
    -p "Wallpaper" \
    -i \
    -show-icons \
    -selected-row "$selected_index" \
    -markup-rows \
    -theme-str 'window { width: 92%; height: 84%; border: 2px; border-radius: 0px; }' \
    -theme-str 'mainbox { children: [inputbar, message, listview]; spacing: 12px; padding: 14px; }' \
    -theme-str 'inputbar { padding: 8px 10px; border-radius: 0px; }' \
    -theme-str 'message { padding: 6px 10px; border-radius: 0px; }' \
    -theme-str 'textbox { background-color: inherit; text-color: inherit; }' \
    -theme-str 'listview { columns: 3; lines: 2; spacing: 10px; cycle: true; dynamic: false; scrollbar: false; }' \
    -theme-str 'element { orientation: vertical; padding: 8px; border-radius: 0px; }' \
    -theme-str 'element selected { border-radius: 0px; }' \
    -theme-str 'element-icon { size: 260px; border-radius: 0px; }' \
    -theme-str 'element-text { horizontal-align: 0.5; vertical-align: 0.5; margin: 6px 0px 0px 0px; }' \
    -theme-str 'textbox-prompt-colon { str: ""; }' \
    -mesg 'Select a wallpaper preview' || pkill rofi
)"

if [[ -n "$wallpaper_name" && -f "$wallpapers_folder/$wallpaper_name" ]]; then
    wall-change "$wallpapers_folder/$wallpaper_name" &
else
    exit 1
fi
