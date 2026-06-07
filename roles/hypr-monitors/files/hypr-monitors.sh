#!/usr/bin/env bash

set -euo pipefail

export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland}"
export PYTHONPATH="$HOME/.config/hypr-monitors${PYTHONPATH:+:$PYTHONPATH}"

exec python3 "$HOME/.config/hypr-monitors/main.py"
