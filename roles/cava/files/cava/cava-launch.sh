#!/usr/bin/env bash
# cava-launch.sh — Merge base config + matugen colors, then launch cava
# Usage: cava-launch [cava args...]

mkdir -p ~/.config/cava

# Merge static base config with dynamic matugen colors
if [ -f ~/.config/cava/colors ]; then
    cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null
else
    cp ~/.config/cava/config_base ~/.config/cava/config 2>/dev/null
fi

exec cava "$@"
