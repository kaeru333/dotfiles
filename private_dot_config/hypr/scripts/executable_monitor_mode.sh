#!/usr/bin/env bash
# モニターモード切替スクリプト
# 使い方: monitor_mode.sh [1|2|3|status]

HYPR_DIR="$HOME/.config/hypr"
MODES_DIR="$HYPR_DIR/modes"
STATE_FILE="/tmp/hypr_monitor_mode"
LOCK_CMD="hyprlock"

show_status() {
    if [[ -f "$STATE_FILE" ]]; then
        local mode
        mode=$(cat "$STATE_FILE")
        echo "現在のモード: $mode"
        hyprctl notify 1 3000 0 "モニターモード: $mode"
    else
        echo "モードが設定されていません"
        hyprctl notify 1 3000 0 "モニターモード: 未設定"
    fi
}

apply_mode() {
    local mode="$1"
    local mon_conf="$MODES_DIR/mode${mode}_monitors.conf"
    local ws_conf="$MODES_DIR/mode${mode}_workspaces.conf"

    # 設定ファイルの存在確認
    if [[ ! -f "$mon_conf" ]] || [[ ! -f "$ws_conf" ]]; then
        echo "エラー: モード${mode}の設定ファイルが見つかりません"
        hyprctl notify 3 3000 0 "エラー: モード${mode}の設定ファイルが見つかりません"
        exit 1
    fi

    # 設定ファイルをコピー
    cp "$mon_conf" "$HYPR_DIR/monitors.conf"
    cp "$ws_conf" "$HYPR_DIR/workspaces.conf"

    # 設定を再読み込み
    hyprctl reload

    # 少し待ってモニターの認識を待つ
    sleep 1

    # ワークスペースの再配置
    case "$mode" in
        1)
            hyprctl --batch "\
                dispatch moveworkspacetomonitor name:shell eDP-1; \
                dispatch moveworkspacetomonitor name:mon DP-2; \
                dispatch moveworkspacetomonitor name:term DP-2; \
                dispatch moveworkspacetomonitor name:web HDMI-A-1; \
                dispatch moveworkspacetomonitor name:chat HDMI-A-1; \
                dispatch moveworkspacetomonitor name:AI HDMI-A-1"
            ;;
        2)
            hyprctl --batch "\
                dispatch moveworkspacetomonitor name:shell DP-1; \
                dispatch moveworkspacetomonitor name:mon DP-2; \
                dispatch moveworkspacetomonitor name:term DP-2; \
                dispatch moveworkspacetomonitor name:web HDMI-A-1; \
                dispatch moveworkspacetomonitor name:chat HDMI-A-1; \
                dispatch moveworkspacetomonitor name:AI HDMI-A-1"
            ;;
        3)
            # HDMI-A-1 の接続有無で分岐
            if hyprctl monitors -j 2>/dev/null | grep -q '"name": "HDMI-A-1"'; then
                hyprctl --batch "\
                    dispatch moveworkspacetomonitor name:shell eDP-1; \
                    dispatch moveworkspacetomonitor name:mon eDP-1; \
                    dispatch moveworkspacetomonitor name:term eDP-1; \
                    dispatch moveworkspacetomonitor name:web HDMI-A-1; \
                    dispatch moveworkspacetomonitor name:chat HDMI-A-1; \
                    dispatch moveworkspacetomonitor name:AI HDMI-A-1"
            else
                # HDMI 未接続: 全ワークスペースを eDP-1 に集約
                hyprctl --batch "\
                    dispatch moveworkspacetomonitor name:shell eDP-1; \
                    dispatch moveworkspacetomonitor name:mon eDP-1; \
                    dispatch moveworkspacetomonitor name:term eDP-1; \
                    dispatch moveworkspacetomonitor name:web eDP-1; \
                    dispatch moveworkspacetomonitor name:chat eDP-1; \
                    dispatch moveworkspacetomonitor name:AI eDP-1"
            fi
            ;;
    esac

    # リッドスイッチの制御
    if [[ "$mode" == "2" ]]; then
        # モード2: 蓋閉じでもスリープしないようバインド解除
        hyprctl keyword unbind "SWITCH,,Lid Switch"
    else
        # モード1/3: リッドスイッチのバインドを復元
        hyprctl keyword "bindl=,switch:off:Lid Switch, exec, $LOCK_CMD"
    fi

    # 状態を保存
    echo "$mode" > "$STATE_FILE"

    # 通知
    local desc
    case "$mode" in
        1) desc="eDP-1 + DP-2(4K) + HDMI(縦)" ;;
        2) desc="DP-2(4K) + DP-1(4K) + HDMI(縦) [蓋閉じ対応]" ;;
        3) desc="eDP-1 + HDMI(横)" ;;
    esac
    echo "モード${mode}に切り替えました: $desc"
    hyprctl notify 1 3000 0 "モニターモード${mode}: $desc"
}

# メイン処理
case "${1:-}" in
    1|2|3)
        apply_mode "$1"
        ;;
    status)
        show_status
        ;;
    *)
        echo "使い方: $0 [1|2|3|status]"
        echo "  1: eDP-1 + DP-2(4K) + HDMI(縦)"
        echo "  2: DP-2(4K) + DP-1(4K) + HDMI(縦) [蓋閉じ対応]"
        echo "  3: eDP-1 + HDMI(横)"
        echo "  status: 現在のモードを表示"
        exit 1
        ;;
esac
