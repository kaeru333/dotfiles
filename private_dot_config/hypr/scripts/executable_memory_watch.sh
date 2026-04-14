#!/usr/bin/env bash
# メモリ使用量監視スクリプト
# 10 秒間隔で /proc/meminfo を監視し、閾値超過時にデスクトップ通知 + Slack 通知を送信する
#
# 閾値 (メモリ使用率):
#   INFO     70% - ログのみ
#   WARNING  80% - デスクトップ通知
#   CRITICAL 90% - デスクトップ通知 + Slack 通知
#   EMERGENCY 95% - デスクトップ通知 + Slack 通知

set -euo pipefail

# --- 設定 ---
INTERVAL=10
LOG_FILE="/tmp/hypr_memory_watch.log"
PID_FILE="/tmp/hypr_memory_watch.pid"
LOG_MAX_LINES=500

THRESHOLD_WARNING=80
THRESHOLD_CRITICAL=90
THRESHOLD_EMERGENCY=95

# クールダウン (秒)
COOLDOWN_WARNING=300    # 5 分
COOLDOWN_CRITICAL=120   # 2 分
COOLDOWN_EMERGENCY=60   # 1 分

# 最終通知時刻
LAST_WARNING=0
LAST_CRITICAL=0
LAST_EMERGENCY=0

# --- 関数 ---

log() {
    local msg="[memory_watch] $(date '+%Y-%m-%d %H:%M:%S') $*"
    echo "$msg" >> "$LOG_FILE"
    # ログローテーション
    local lines
    lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
    if (( lines > LOG_MAX_LINES )); then
        local excess=$(( lines - LOG_MAX_LINES ))
        sed -i "1,${excess}d" "$LOG_FILE"
    fi
}

# メモリ使用率を取得 (%)
get_memory_usage() {
    awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {printf "%d", (total-avail)*100/total}' /proc/meminfo
}

# メモリ情報の詳細を取得
get_memory_detail() {
    awk '
        /MemTotal/     {total=$2}
        /MemAvailable/ {avail=$2}
        /SwapTotal/    {stotal=$2}
        /SwapFree/     {sfree=$2}
        END {
            used = total - avail
            printf "RAM: %.1fGB / %.1fGB (空き %.1fGB)\n", used/1048576, total/1048576, avail/1048576
            if (stotal > 0) {
                sused = stotal - sfree
                printf "Swap: %.1fGB / %.1fGB (空き %.1fGB)", sused/1048576, stotal/1048576, sfree/1048576
            } else {
                printf "Swap: なし"
            }
        }
    ' /proc/meminfo
}

# 上位メモリ消費プロセスを取得
get_top_processes() {
    ps --no-headers -eo rss,comm --sort=-rss 2>/dev/null | head -5 | awk '{printf "  %dMB %s\n", $1/1024, $2}'
}

# デスクトップ通知
notify_desktop() {
    local urgency="$1"
    local title="$2"
    local body="$3"
    notify-send -u "$urgency" -a "Memory Watch" "$title" "$body" 2>/dev/null || true
}

# Slack 通知
notify_slack() {
    local message="$1"
    notify-slack "$message" 2>/dev/null || true
}

# クールダウンチェック
can_notify() {
    local level="$1"
    local now
    now=$(date +%s)

    case "$level" in
        WARNING)
            if (( now - LAST_WARNING >= COOLDOWN_WARNING )); then
                LAST_WARNING=$now
                return 0
            fi
            ;;
        CRITICAL)
            if (( now - LAST_CRITICAL >= COOLDOWN_CRITICAL )); then
                LAST_CRITICAL=$now
                return 0
            fi
            ;;
        EMERGENCY)
            if (( now - LAST_EMERGENCY >= COOLDOWN_EMERGENCY )); then
                LAST_EMERGENCY=$now
                return 0
            fi
            ;;
    esac
    return 1
}

# PID ファイル管理
cleanup() {
    rm -f "$PID_FILE"
    log "停止"
    exit 0
}

# --- メイン ---

# 既存プロセスの終了
if [[ -f "$PID_FILE" ]]; then
    old_pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
    if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
        kill "$old_pid" 2>/dev/null || true
        sleep 1
    fi
fi

echo $$ > "$PID_FILE"
trap cleanup EXIT INT TERM

log "起動 (PID: $$, 間隔: ${INTERVAL}秒)"

while true; do
    usage=$(get_memory_usage)

    if (( usage >= THRESHOLD_EMERGENCY )); then
        if can_notify EMERGENCY; then
            detail=$(get_memory_detail)
            top_procs=$(get_top_processes)
            log "EMERGENCY: メモリ使用率 ${usage}%"
            notify_desktop "critical" "🚨 メモリ緊急 (${usage}%)" "${detail}\n\n上位プロセス:\n${top_procs}"
            notify_slack "🚨 メモリ緊急警報: ${usage}% 使用中。${detail}"
        fi
    elif (( usage >= THRESHOLD_CRITICAL )); then
        if can_notify CRITICAL; then
            detail=$(get_memory_detail)
            top_procs=$(get_top_processes)
            log "CRITICAL: メモリ使用率 ${usage}%"
            notify_desktop "critical" "⚠️ メモリ危険 (${usage}%)" "${detail}\n\n上位プロセス:\n${top_procs}"
            notify_slack "⚠️ メモリ危険: ${usage}% 使用中。${detail}"
        fi
    elif (( usage >= THRESHOLD_WARNING )); then
        if can_notify WARNING; then
            detail=$(get_memory_detail)
            log "WARNING: メモリ使用率 ${usage}%"
            notify_desktop "normal" "メモリ警告 (${usage}%)" "${detail}"
        fi
    fi

    sleep "$INTERVAL"
done
