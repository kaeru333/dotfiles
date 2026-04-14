#!/usr/bin/env bash
# Waybar カスタムメモリウィジェット
# JSON 形式で出力し、閾値に応じて CSS クラスを設定する
#
# 出力形式: {"text": "XX%", "tooltip": "...", "class": "normal|warning|critical|emergency"}

set -euo pipefail

# 上位プロセス (awk で \\n エスケープ済み文字列を生成)
top_procs=$(ps --no-headers -eo rss,comm --sort=-rss 2>/dev/null | head -5 | awk '{printf "%dMB %s\\n", $1/1024, $2}')

# awk でメモリ情報取得 + JSON 生成を一括処理
awk -v top_procs="$top_procs" '
    /MemTotal/     {total=$2}
    /MemAvailable/ {avail=$2}
    /SwapTotal/    {stotal=$2}
    /SwapFree/     {sfree=$2}
    END {
        gsub(/\n/, "\\n", top_procs)
        used = total - avail
        pct = int(used * 100 / total)

        ram = sprintf("RAM: %.1fGB / %.1fGB (空き %.1fGB)", used/1048576, total/1048576, avail/1048576)
        if (stotal > 0) {
            sused = stotal - sfree
            swap = sprintf("Swap: %.1fGB / %.1fGB", sused/1048576, stotal/1048576)
        } else {
            swap = "Swap: なし"
        }

        if (pct >= 95)      class = "emergency"
        else if (pct >= 90)  class = "critical"
        else if (pct >= 80)  class = "warning"
        else                 class = "normal"

        tooltip = ram "\\n" swap "\\n\\n上位プロセス:\\n" top_procs

        printf "{\"text\": \"%d%%\", \"tooltip\": \"%s\", \"class\": \"%s\"}\n", pct, tooltip, class
    }
' /proc/meminfo
