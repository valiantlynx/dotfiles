#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path

from PySide6.QtCore import Property, QObject, QUrl, Signal, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


APP_DIR = Path(__file__).resolve().parent


def run_json(*args):
    result = subprocess.run(args, check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


class Backend(QObject):
    monitorsChanged = Signal()
    applyFinished = Signal(str, bool)

    def __init__(self):
        super().__init__()
        self._monitors = []
        self.refresh()

    @Property("QVariantList", notify=monitorsChanged)
    def monitors(self):
        return self._monitors

    @Slot()
    def refresh(self):
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
