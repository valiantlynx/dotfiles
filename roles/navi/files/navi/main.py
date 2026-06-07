#!/usr/bin/env python3

import json
import random
import sys
from pathlib import Path

from PySide6.QtCore import Property, QObject, QTimer, QUrl, Signal, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


APP_DIR = Path(__file__).resolve().parent
MATUGEN_THEME_PATH = Path.home() / ".config" / "opencode" / "themes" / "matugen.json"


class Backend(QObject):
    themeChanged = Signal()
    statusChanged = Signal()

    def __init__(self):
        super().__init__()
        self._theme = self._load_theme()
        self._title = "Navi"
        self._subtitle = "Ambient mode"
        self._line = "Ready. Machine-core link will come later."
        self._pulse = 0
        self._messages = [
            "Ready. Machine-core link will come later.",
            "Listening for shape, not answers.",
            "Theme synchronized.",
            "Orbit stable.",
            "Presence online.",
        ]
        self._timer = QTimer(self)
        self._timer.setInterval(9000)
        self._timer.timeout.connect(self.rotate_message)
        self._timer.start()

    @Property("QVariantMap", notify=themeChanged)
    def theme(self):
        return self._theme

    @Property(str, notify=statusChanged)
    def title(self):
        return self._title

    @Property(str, notify=statusChanged)
    def subtitle(self):
        return self._subtitle

    @Property(str, notify=statusChanged)
    def line(self):
        return self._line

    @Property(int, notify=statusChanged)
    def pulse(self):
        return self._pulse

    def _load_theme(self):
        fallback = {
            "background": "#0c1017",
            "backgroundPanel": "#141a23",
            "backgroundElement": "#1a2230",
            "border": "#2b3648",
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
    def refresh_theme(self):
        self._theme = self._load_theme()
        self.themeChanged.emit()

    @Slot()
    def rotate_message(self):
        current = self._line
        choices = [message for message in self._messages if message != current]
        if choices:
            self._line = random.choice(choices)
        self._pulse += 1
        self.statusChanged.emit()

    @Slot()
    def next_message(self):
        self.rotate_message()


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
