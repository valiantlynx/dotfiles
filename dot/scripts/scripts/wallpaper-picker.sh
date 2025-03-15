#!/usr/bin/env bash

wallpaper_path=$HOME/Downloads/dot/wallpapers
wallpapers_folder=$HOME/Downloads/dot/wallpapers/others
wallpaper_name="$(ls $wallpapers_folder | rofi -dmenu || pkill rofi)"

if [[ -f $wallpapers_folder/$wallpaper_name ]]; then
    ln -sf "$wallpapers_folder/$wallpaper_name" "$wallpaper_path/wallpaper"
    wall-change "$wallpaper_path/wallpaper"
else
    exit 1
fi
