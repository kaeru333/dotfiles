#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
sketchybar --set "$NAME" label="$(date '+%a %m/%d %H:%M')"
