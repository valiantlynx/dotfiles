#!/usr/bin/env bash

set -euo pipefail

PROFILE_DIR="${HOME}/.config/vivaldi"

if [[ ! -d "$PROFILE_DIR" ]]; then
    printf 'Vivaldi profile directory not found: %s\n' "$PROFILE_DIR" >&2
    exit 1
fi

has_vivaldi_processes=false
has_vivaldi_window=false

if pgrep -x vivaldi-bin >/dev/null 2>&1; then
    has_vivaldi_processes=true
fi

if command -v hyprctl >/dev/null 2>&1; then
    if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(((.class // "") | ascii_downcase) | contains("vivaldi"))' >/dev/null 2>&1; then
        has_vivaldi_window=true
    fi
fi

if [[ "$has_vivaldi_processes" == true && "$has_vivaldi_window" == true ]]; then
    printf 'Vivaldi already has a live window. Asking the running instance for a new window.\n'
    exec vivaldi --new-window about:blank >/dev/null 2>&1
fi

if [[ "$has_vivaldi_processes" == true && "$has_vivaldi_window" == false ]]; then
    printf 'Vivaldi processes are running, but no Hyprland window exists. Force-restarting Vivaldi.\n'
    pkill -x vivaldi-bin 2>/dev/null || true
    pkill -f '/opt/vivaldi/chrome_crashpad_handler' 2>/dev/null || true
    sleep 2
fi

for singleton_file in SingletonLock SingletonSocket SingletonCookie; do
    rm -f "$PROFILE_DIR/$singleton_file"
done

printf 'Removed stale Vivaldi singleton files.\n'
exec vivaldi >/dev/null 2>&1
