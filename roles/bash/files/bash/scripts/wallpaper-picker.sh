#!/usr/bin/env bash

wallpapers_folder=$HOME/.dotfiles/shell-wallpapers
wallpaper_name="$(ls "$wallpapers_folder" | rofi -dmenu -p "Wallpaper" || pkill rofi)"

if [[ -n "$wallpaper_name" && -f "$wallpapers_folder/$wallpaper_name" ]]; then
    wall-change "$wallpapers_folder/$wallpaper_name"
else
    exit 1
fi
