#!/usr/bin/env python3
"""
Schedule scraper stub.

The original script scraped a Danish school schedule (uddataplus.dk) using
Selenium + Firefox. That's specific to the friend's setup and not applicable here.

To add your own schedule source, implement update_schedule() to write JSON to:
  ~/.cache/quickshell/schedule/schedule.json

Expected format:
{
  "header": "Monday, 31 Mar (Today)",
  "lessons": [
    {
      "type": "class",
      "time": "08:30-09:15",
      "subject": "Math",
      "room": "A201",
      "teacher": "Name",
      "start": <epoch>,
      "end": <epoch>,
      "width": 100,
      "char_limit": 20,
      "is_compact": false
    },
    {
      "type": "gap",
      "width": 30,
      "desc": "15m",
      "start": <epoch>,
      "end": <epoch>
    }
  ],
  "link": ""
}
"""

import json
import os

CACHE_FILE = os.path.expanduser("~/.cache/quickshell/schedule/schedule.json")


def update_schedule():
    output = {"header": "No Schedule Configured", "lessons": [], "link": ""}
    os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
    with open(CACHE_FILE, "w") as f:
        json.dump(output, f)


if __name__ == "__main__":
    update_schedule()
