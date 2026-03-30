#!/usr/bin/env bash
# Auto-restart wrapper for quickshell Main.qml
# If Main.qml crashes/exits, restart it after a brief delay
while true; do
    quickshell -p ~/.config/quickshell/Main.qml 2>&1 | tee -a /tmp/qs_main_out.log
    echo "[$(date)] Main.qml exited with code $? — restarting in 2s..." >> /tmp/qs_main_out.log
    sleep 2
done
