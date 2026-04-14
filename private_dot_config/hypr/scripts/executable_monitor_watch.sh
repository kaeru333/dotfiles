#!/usr/bin/env bash
# モニター自動切替スクリプト (socket2 イベント駆動)
# monitoradded / monitorremoved イベントを監視し、適切なモードに自動切替する

HYPR_DIR="$HOME/.config/hypr"
STATE_FILE="/tmp/hypr_monitor_mode"
COOLDOWN_SEC=3
LAST_APPLY=0

log() {
    echo "[monitor_watch] $(date '+%H:%M:%S') $*"
}

# 接続中モニターからモードを判定する
detect_mode() {
    local monitors
    monitors=$(hyprctl monitors -j 2>/dev/null) || return 1

    if echo "$monitors" | grep -q '"name": "DP-2"'; then
        echo "1"
    else
        echo "3"
    fi
}

# モード適用 (変更がある場合のみ)
# 引数: $1 = "force" で現在モードとの比較をスキップ
try_apply() {
    local force="${1:-}"
    local now
    now=$(date +%s)

    # クールダウンチェック (force 時はスキップ)
    if [[ "$force" != "force" ]] && (( now - LAST_APPLY < COOLDOWN_SEC )); then
        log "クールダウン中、スキップ"
        return
    fi

    local new_mode
    new_mode=$(detect_mode) || { log "detect_mode 失敗"; return; }

    # 現在のモードと比較 (force でなければ)
    if [[ "$force" != "force" && -f "$STATE_FILE" ]]; then
        local current_mode
        current_mode=$(cat "$STATE_FILE")
        if [[ "$new_mode" == "$current_mode" ]]; then
            log "モード変更なし (mode${current_mode})"
            return
        fi
    fi

    log "モード適用: mode${new_mode} (${force:-auto})"
    LAST_APPLY=$now
    "$HYPR_DIR/scripts/monitor_mode.sh" "$new_mode"
}

# socket2 イベントリスナー (再接続ループ付き)
listen_events() {
    local socket_path
    socket_path="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

    while true; do
        if [[ ! -S "$socket_path" ]]; then
            log "ソケット待機中: $socket_path"
            sleep 2
            continue
        fi

        log "socket2 に接続"

        # プロセス置換で while を現在のシェルで実行 (サブシェル回避)
        while IFS= read -r line; do
            case "$line" in
                monitoradded\>\>*|monitorremoved\>\>*)
                    log "イベント検出: $line"
                    # イベント後少し待ってからモニター状態を確認
                    sleep 1
                    try_apply
                    ;;
            esac
        done < <(socat -u "UNIX-CONNECT:${socket_path}" STDOUT 2>/dev/null)

        log "socat 切断、3秒後に再接続"
        sleep 3
    done
}

# メイン
log "起動"

# 起動時: ステートファイルに関係なく必ずモード適用
try_apply force

# イベント監視開始
listen_events
