#!/usr/bin/env bash
# Battery level (%) + charging state. Icon reflects level; bolt while charging.
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# Nerd Font glyphs (built from UTF-8 bytes — literal PUA chars get stripped).
BAT_FULL=$(printf '\xef\x89\x80')   # U+F240
BAT_3Q=$(printf '\xef\x89\x81')     # U+F241
BAT_HALF=$(printf '\xef\x89\x82')   # U+F242
BAT_1Q=$(printf '\xef\x89\x83')     # U+F243
BAT_EMPTY=$(printf '\xef\x89\x84')  # U+F244
BOLT=$(printf '\xef\x83\xa7')       # U+F0E7

batt=$(pmset -g batt)
percent=$(printf '%s\n' "$batt" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
[ -z "$percent" ] && { sketchybar --set "$NAME" icon="$BAT_EMPTY" label="N/A"; exit 0; }

charging=false
case "$batt" in
  *"AC Power"*) charging=true ;;
esac

if   [ "$percent" -ge 90 ]; then icon="$BAT_FULL"
elif [ "$percent" -ge 60 ]; then icon="$BAT_3Q"
elif [ "$percent" -ge 40 ]; then icon="$BAT_HALF"
elif [ "$percent" -ge 15 ]; then icon="$BAT_1Q"
else                             icon="$BAT_EMPTY"
fi

color=0xffcad3f5
if $charging; then
  icon="$BOLT"            # charging / on AC
  color=0xffa6da95         # green
elif [ "$percent" -le 20 ]; then
  color=0xffed8796         # red — low
fi

sketchybar --set "$NAME" icon="$icon" label="${percent}%" icon.color=$color
