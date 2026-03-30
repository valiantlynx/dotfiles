#!/usr/bin/env bash
set -euo pipefail

echo "=== mpvpaper build-from-source ==="

# --- Dependencies ---
sudo apt-get update || true
sudo apt-get install -y \
    git meson ninja-build pkg-config \
    libmpv-dev libwlroots-dev wayland-protocols libwayland-dev

# --- Clone ---
BUILD_DIR="$HOME/mpvpaper_build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

git clone --single-branch --depth 1 https://github.com/GhostNaN/mpvpaper.git
cd mpvpaper

# --- Build ---
meson setup build --prefix=/usr/local
ninja -C build

# --- Install ---
sudo ninja -C build install

echo "=== mpvpaper installed ==="
mpvpaper --version 2>/dev/null || echo "(version check not supported)"
