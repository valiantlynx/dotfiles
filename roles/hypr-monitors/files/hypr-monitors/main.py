#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path

from PySide6.QtCore import Property, QObject, QUrl, Signal, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


APP_DIR = Path(__file__).resolve().parent
MATUGEN_THEME_PATH = Path.home() / ".config" / "opencode" / "themes" / "matugen.json"


def run_json(*args):
    result = subprocess.run(args, check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


class Backend(QObject):
    monitorsChanged = Signal()
    applyFinished = Signal(str, bool)
    themeChanged = Signal()

    def __init__(self):
        super().__init__()
        self._monitors = []
        self._theme = self._load_theme()
        self.refresh()

    @Property("QVariantList", notify=monitorsChanged)
    def monitors(self):
        return self._monitors

    @Property("QVariantMap", notify=themeChanged)
    def theme(self):
        return self._theme

    def _load_theme(self):
        fallback = {
            "background": "#0c1017",
            "backgroundPanel": "#141a23",
            "backgroundElement": "#1a2230",
            "border": "#2b3648",
            "borderActive": "#44546a",
            "text": "#edf3ff",
            "textMuted": "#a7b7cc",
            "primary": "#79a8ff",
            "secondary": "#8fd19e",
            "accent": "#c8a0d0",
            "error": "#ff9a9a",
        }
        if not MATUGEN_THEME_PATH.exists():
            return fallback
        try:
            data = json.loads(MATUGEN_THEME_PATH.read_text())
            defs = data.get("defs", {})
            theme = data.get("theme", {})
            resolved = {}
            for key, value in fallback.items():
                theme_key = theme.get(key, key)
                resolved[key] = defs.get(theme_key, theme.get(key, value))
            return resolved
        except Exception:
            return fallback

    @Slot()
    def refresh(self):
        self._theme = self._load_theme()
        self.themeChanged.emit()
        try:
            data = run_json("hyprctl", "monitors", "-j")
        except Exception:
            return

        min_x = min((item.get("x", 0) for item in data), default=0)
        min_y = min((item.get("y", 0) for item in data), default=0)
        monitors = []
        for item in data:
            modes = []
            for mode in item.get("availableModes", []):
                if "@" not in mode:
                    continue
                res, refresh = mode.split("@", 1)
                if "x" not in res:
                    continue
                width, height = res.split("x", 1)
                try:
                    modes.append(
                        {
                            "label": mode.replace("Hz", ""),
                            "width": int(width),
                            "height": int(height),
                            "refresh": int(round(float(refresh.replace("Hz", "")))),
                        }
                    )
                except ValueError:
                    continue

            current_refresh = int(round(float(item.get("refreshRate", 60))))
            scale = float(item.get("scale", 1.0))
            monitors.append(
                {
                    "name": item["name"],
                    "description": item.get("description", item["name"]),
                    "width": int(item["width"]),
                    "height": int(item["height"]),
                    "refresh": current_refresh,
                    "scale": scale,
                    "transform": int(item.get("transform", 0)),
                    "focused": bool(item.get("focused", False)),
                    "availableModes": modes,
                    "x": int(item.get("x", 0)),
                    "y": int(item.get("y", 0)),
                    "layoutX": int(item.get("x", 0) - min_x),
                    "layoutY": int(item.get("y", 0) - min_y),
                }
            )

        self._monitors = monitors
        self.monitorsChanged.emit()

    @Slot(str)
    def apply(self, monitors_json):
        try:
            monitors = json.loads(monitors_json)
            min_x = min((int(m["layoutX"]) for m in monitors), default=0)
            min_y = min((int(m["layoutY"]) for m in monitors), default=0)
            commands = []
            for monitor in monitors:
                x = int(monitor["layoutX"]) - min_x
                y = int(monitor["layoutY"]) - min_y
                width = int(monitor["width"])
                height = int(monitor["height"])
                refresh = int(monitor["refresh"])
                scale = float(monitor["scale"])
                transform = int(monitor.get("transform", 0))
                command = (
                    f"keyword monitor {monitor['name']},{width}x{height}@{refresh},{x}x{y},{scale},transform,{transform}"
                )
                commands.append(command)

            subprocess.run(["hyprctl", "--batch", " ; ".join(commands)], check=True, capture_output=True, text=True)
            self.applyFinished.emit("Applied monitor layout", True)
            self.refresh()
        except subprocess.CalledProcessError as exc:
            message = exc.stderr.strip() or exc.stdout.strip() or "Failed to apply monitor layout"
            self.applyFinished.emit(message, False)
        except Exception as exc:
            self.applyFinished.emit(str(exc), False)


def main():
    app = QGuiApplication(sys.argv)
    backend = Backend()
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backend", backend)
    engine.load(QUrl.fromLocalFile(str(APP_DIR / "Main.qml")))
    if not engine.rootObjects():
        return 1
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
