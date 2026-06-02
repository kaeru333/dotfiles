#!/usr/bin/env bash
# Memory usage (%) — used = (active + wired + compressed) / total.
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

total=$(sysctl -n hw.memsize)
stats=$(vm_stat)
page_size=$(printf '%s\n' "$stats" | sed -n 's/.*page size of \([0-9]*\) bytes.*/\1/p')
val() { printf '%s\n' "$stats" | sed -n "s/^$1: *\([0-9][0-9]*\)\.\{0,1\}$/\1/p"; }
active=$(val "Pages active")
wired=$(val "Pages wired down")
compressed=$(val "Pages occupied by compressor")
: "${active:=0}" "${wired:=0}" "${compressed:=0}" "${page_size:=4096}" "${total:=1}"

used=$(( (active + wired + compressed) * page_size ))
percent=$(( used * 100 / total ))

if   [ "$percent" -ge 85 ]; then color=0xffed8796   # red
elif [ "$percent" -ge 70 ]; then color=0xffeed49f   # yellow
else                            color=0xffa6da95     # green
fi

sketchybar --set "$NAME" label="${percent}%" label.color=$color
