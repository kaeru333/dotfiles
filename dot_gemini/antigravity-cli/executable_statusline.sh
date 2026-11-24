#!/bin/bash
# Antigravity CLI 用カスタムステータスライン (mode · model · effort · ctx 1行表示)

input=$(cat)
[ -z "$input" ] && exit 0

parsed=$(printf '%s' "$input" | jq -r '
  [
    (.cycle_mode // "default"),
    (.model.display_name // .model.id // "agy"),
    (.model.effort // ""),
    ((.context_window.used_percentage // 0) | tostring),
    (.vim.mode // ""),
    ((.artifact_count // 0) | tostring)
  ]
  | map(tostring | gsub("[\r\n\u001f]"; " "))
  | join("\u001f")
' 2>/dev/null) || exit 0

[ -z "$parsed" ] && exit 0

IFS=$'\x1f' read -r MODE MODEL EFFORT USED_PCT VIM_MODE ARTIFACT_CNT <<< "$parsed"

R=$'\033[0m'
DIM=$'\033[38;5;245m'
SEP="${DIM} · ${R}"
C_MODEL=$'\033[38;5;203m'
C_EFFORT=$'\033[38;5;178m'

case "$MODE" in
  auto)         C_MODE=$'\033[38;5;111m' ;;
  accept-edits) C_MODE=$'\033[38;5;178m' ;;
  plan)         C_MODE=$'\033[38;5;183m' ;;
  *)            C_MODE=$'\033[38;5;245m' ;;
esac

USED_FMT=$(LC_NUMERIC=C printf "%.1f" "${USED_PCT:-0}" 2>/dev/null || printf "0.0")
USED_INT=${USED_FMT%.*}
USED_INT=${USED_INT:-0}
if [ "$USED_INT" -ge 80 ] 2>/dev/null; then
  C_CTX=$'\033[38;5;203m'
elif [ "$USED_INT" -ge 60 ] 2>/dev/null; then
  C_CTX=$'\033[38;5;227m'
else
  C_CTX=$'\033[38;5;155m'
fi

parts=()
parts+=("${C_MODE}${MODE}${R}")
parts+=("${C_MODEL}${MODEL}${R}")

if [ -n "$EFFORT" ] && [[ "${MODEL,,}" != *"(${EFFORT,,})"* ]]; then
  parts+=("${C_EFFORT}${EFFORT}${R}")
fi

parts+=("${C_CTX}ctx ${USED_FMT}%${R}")

if [ -n "$VIM_MODE" ] && [ "$VIM_MODE" != "NORMAL" ]; then
  case "$VIM_MODE" in
    INSERT)      vim_badge="-- INSERT --" ;;
    VISUAL)      vim_badge="-- VISUAL --" ;;
    "VISUAL LINE") vim_badge="-- V-LINE --" ;;
    *)           vim_badge="-- ${VIM_MODE} --" ;;
  esac
  parts+=("${C_EFFORT}${vim_badge}${R}")
fi

if [ -n "$ARTIFACT_CNT" ] && [ "$ARTIFACT_CNT" -gt 0 ] 2>/dev/null; then
  parts+=("${C_MODE}${ARTIFACT_CNT} artifacts${R}")
fi

out=""
for i in "${!parts[@]}"; do
  if [ "$i" -gt 0 ]; then
    out+="$SEP"
  fi
  out+="${parts[$i]}"
done

printf '%s\n' "$out"
exit 0
