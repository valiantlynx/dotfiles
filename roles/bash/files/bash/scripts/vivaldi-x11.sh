#!/usr/bin/env bash

set -euo pipefail

exec /usr/bin/vivaldi-stable --ozone-platform=x11 "$@"
