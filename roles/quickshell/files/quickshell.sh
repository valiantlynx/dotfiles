#!/usr/bin/env bash
set -euo pipefail

# Quickshell build-from-source script for Ubuntu 24.04+
# Builds with: Wayland, Hyprland, Pipewire, PAM, SystemTray, MPRIS, Jemalloc

QUICKSHELL_VERSION="${1:-v0.2.1}"
BUILD_DIR="$HOME/quickshell_build"
INSTALL_PREFIX="/usr/local"

echo "==> Installing build dependencies..."
sudo apt-get update -qq || true
sudo apt-get install -y --no-install-recommends \
    cmake ninja-build pkg-config git \
    qt6-base-dev qt6-declarative-dev qt6-declarative-private-dev \
    qt6-wayland-dev qt6-wayland-dev-tools qt6-wayland-private-dev \
    qt6-svg-dev qt6-shadertools-dev \
    libwayland-dev wayland-protocols \
    libdrm-dev libgbm-dev \
    libpipewire-0.3-dev \
    libpam0g-dev \
    libvulkan-dev spirv-tools \
    libjemalloc-dev \
    libpolkit-agent-1-dev libglib2.0-dev \
    libdbus-1-dev \
    libcli11-dev

echo "==> Cloning Quickshell ${QUICKSHELL_VERSION}..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
git clone --depth 1 --branch "$QUICKSHELL_VERSION" \
    https://github.com/quickshell-mirror/quickshell.git "$BUILD_DIR/quickshell" 2>/dev/null || \
git clone --depth 1 \
    https://github.com/quickshell-mirror/quickshell.git "$BUILD_DIR/quickshell"

cd "$BUILD_DIR/quickshell"

echo "==> Configuring build..."
cmake -GNinja -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DDISTRIBUTOR="Ubuntu dotfiles (valiantlynx)" \
    -DWAYLAND=ON \
    -DHYPRLAND=ON \
    -DSERVICE_PIPEWIRE=ON \
    -DSERVICE_STATUS_NOTIFIER=ON \
    -DSERVICE_MPRIS=ON \
    -DSERVICE_PAM=ON \
    -DUSE_JEMALLOC=ON \
    -DCRASH_REPORTER=OFF

echo "==> Building (this may take a few minutes)..."
cmake --build build -j"$(nproc)"

echo "==> Installing..."
sudo cmake --install build

echo "==> Cleaning up build directory..."
rm -rf "$BUILD_DIR"

echo "==> Quickshell installed successfully!"
quickshell --version 2>/dev/null || echo "(version check not available)"
