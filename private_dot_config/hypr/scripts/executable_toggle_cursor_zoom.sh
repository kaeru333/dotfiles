#!/usr/bin/env bash
# カーソル周辺のズームをトグルする
# 通常時: zoom_factor = 1.0
# ズーム時: zoom_factor = 3.0

ZOOM_ON=3.0
ZOOM_OFF=1.0

current=$(hyprctl getoption cursor:zoom_factor -j | grep -oE '"float":\s*[0-9.]+' | grep -oE '[0-9.]+')

# 1.0 より大きければオフ、そうでなければオン
if awk "BEGIN {exit !($current > 1.05)}"; then
    hyprctl keyword cursor:zoom_factor "$ZOOM_OFF" >/dev/null
else
    hyprctl keyword cursor:zoom_factor "$ZOOM_ON" >/dev/null
fi
