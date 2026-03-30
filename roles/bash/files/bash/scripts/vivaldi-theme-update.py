#!/usr/bin/env python3
"""
Apply matugen-generated colors to Vivaldi browser.

Two approaches:
1. Custom CSS modifications (if enabled via vivaldi://experiments)
   - Generates CSS at ~/.config/vivaldi/matugen-css/matugen.css
   - Set Vivaldi CSS modifications dir to that path

2. Theme override in Preferences (applied on Vivaldi restart)
   - Creates/updates a "Matugen" theme in the themes collection

Usage: python3 vivaldi-theme-update.py
"""

import json
import os
import sys
import uuid

COLORS_FILE = "/tmp/matugen-vivaldi-colors.json"
PREFS_FILE = os.path.expanduser("~/.config/vivaldi/Default/Preferences")
CSS_DIR = os.path.expanduser("~/.config/vivaldi/matugen-css")


def main():
    if not os.path.exists(COLORS_FILE):
        return 1

    with open(COLORS_FILE) as f:
        colors = json.load(f)

    # --- Approach 1: Generate CSS file for Vivaldi CSS modifications ---
    os.makedirs(CSS_DIR, exist_ok=True)
    css_content = f"""\
/* Matugen dynamic colors for Vivaldi UI */
/* Enable via vivaldi://experiments -> Allow CSS modifications */
/* Set directory to: {CSS_DIR} */

:root {{
  --colorBg: {colors["bg"]} !important;
  --colorFg: {colors["fg"]} !important;
  --colorHighlightBg: {colors["highlight"]} !important;
  --colorAccentBg: {colors["accent"]} !important;
}}

/* Tab bar */
#tabs-tabbar-container {{
  background-color: {colors["bg"]} !important;
}}

/* Active tab */
.tab-position .tab.active .tab-header {{
  background-color: {colors["accent"]} !important;
  color: {colors["onPrimary"]} !important;
}}

/* Address bar */
.UrlBar .UrlBar--AddressField {{
  background-color: {colors["surfaceContainer"]} !important;
  border-color: {colors["outline"]} !important;
}}

.UrlBar--Focused .UrlBar--AddressField {{
  border-color: {colors["accent"]} !important;
}}

/* Panel sidebar */
#panels-container {{
  background-color: {colors["surface"]} !important;
}}

/* Bookmark bar */
.bookmark-bar {{
  background-color: {colors["bg"]} !important;
}}

/* Status bar */
footer.StatusBar {{
  background-color: {colors["bg"]} !important;
}}
"""

    with open(os.path.join(CSS_DIR, "matugen.css"), "w") as f:
        f.write(css_content)

    # --- Approach 2: Update Preferences (needs restart) ---
    if not os.path.exists(PREFS_FILE):
        return 0

    try:
        with open(PREFS_FILE) as f:
            prefs = json.load(f)

        vivaldi = prefs.setdefault("vivaldi", {})
        themes = vivaldi.setdefault("themes", {})
        collection = themes.setdefault("collection", [])

        # Find or create a "Matugen" theme
        matugen_theme = None
        for theme in collection:
            if theme.get("name") == "Matugen":
                matugen_theme = theme
                break

        if not matugen_theme:
            matugen_theme = {"id": str(uuid.uuid4()), "name": "Matugen", "version": 2}
            collection.append(matugen_theme)

        # Set theme colors
        matugen_theme["colorBg"] = colors["bg"] + "ff"
        matugen_theme["colorFg"] = colors["fg"] + "ff"
        matugen_theme["colorHighlightBg"] = colors["highlight"] + "ff"
        matugen_theme["colorAccentBg"] = colors["accent"] + "ff"

        # Set as active theme
        themes["current"] = matugen_theme["id"]

        with open(PREFS_FILE, "w") as f:
            json.dump(prefs, f, separators=(",", ":"))

    except Exception:
        pass  # Don't break if Vivaldi prefs are locked

    return 0


if __name__ == "__main__":
    sys.exit(main())
