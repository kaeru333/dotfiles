#!/usr/bin/env bash
# Per-workspace updater. $1 = this item's workspace id.
# FOCUSED_WORKSPACE is provided by the aerospace_workspace_change event.
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

sid="$1"

if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
  # current workspace -> highlighted pill, dark label
  sketchybar --set "$NAME" drawing=on background.drawing=on label.color=0xff11111b
elif aerospace list-windows --workspace "$sid" 2>/dev/null | grep -q .; then
  # has windows but not focused -> shown, no highlight
  sketchybar --set "$NAME" drawing=on background.drawing=off label.color=0xffcad3f5
else
  # empty & not focused -> hidden
  sketchybar --set "$NAME" drawing=off
fi
