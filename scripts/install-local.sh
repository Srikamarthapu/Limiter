#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="${LIMITER_BUILD_ROOT:-$HOME/Library/Caches/LimiterBuild}"
APP="$BUILD_ROOT/Limiter.app"

if [[ ! -d "$APP" ]]; then
  "$ROOT/scripts/package-app.sh"
fi

ditto "$APP" "/Applications/Limiter.app"
open "/Applications/Limiter.app"
printf 'Installed and opened /Applications/Limiter.app\n'
