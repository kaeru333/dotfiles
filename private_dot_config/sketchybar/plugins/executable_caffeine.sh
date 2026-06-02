#!/usr/bin/env bash
# Caffeine toggle — cycle through keep-awake modes on click.
#   click order: off -> system only -> screen+system -> all -> off ...
# State persists in /tmp; the running caffeinate process is tracked by PID
# so we never touch other tools' transient `caffeinate -i -t N` assertions.

PIDFILE="/tmp/sketchybar_caffeinate.pid"
STATEFILE="/tmp/sketchybar_caffeinate.state"

# Catppuccin Macchiato
OFF_COLOR=0xff6e738d   # overlay0 (dim)  — off
SYS_COLOR=0xffa6da95   # green           — system only   (-i)
SCR_COLOR=0xfff5a97f   # peach           — screen+system (-d -i)
ALL_COLOR=0xffed8796   # red             — everything    (-d -i -m -s)

kill_caff() {
  [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null
  rm -f "$PIDFILE"
}

start_caff() { # $1 = flags (intentionally unquoted to word-split)
  # shellcheck disable=SC2086
  /usr/bin/caffeinate $1 &
  echo $! > "$PIDFILE"
}

running() {
  [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null
}

state=0
[ -f "$STATEFILE" ] && state=$(cat "$STATEFILE" 2>/dev/null)
case "$state" in 0|1|2|3) ;; *) state=0 ;; esac

if [ "$1" = "toggle" ]; then
  state=$(( (state + 1) % 4 ))
  kill_caff
  case "$state" in
    1) start_caff "-i" ;;
    2) start_caff "-d -i" ;;
    3) start_caff "-d -i -m -s" ;;
  esac
  echo "$state" > "$STATEFILE"
fi

# Self-heal: if a mode is set but the process died (kill, reboot, timeout),
# fall back to off so the indicator matches reality.
if [ "$state" != "0" ] && ! running; then
  state=0
  echo 0 > "$STATEFILE"
fi

case "$state" in
  0) sketchybar --set "$NAME" icon.color=$OFF_COLOR label.drawing=off ;;
  1) sketchybar --set "$NAME" icon.color=$SYS_COLOR label="SYS" label.color=$SYS_COLOR label.drawing=on ;;
  2) sketchybar --set "$NAME" icon.color=$SCR_COLOR label="SCR" label.color=$SCR_COLOR label.drawing=on ;;
  3) sketchybar --set "$NAME" icon.color=$ALL_COLOR label="ALL" label.color=$ALL_COLOR label.drawing=on ;;
esac
