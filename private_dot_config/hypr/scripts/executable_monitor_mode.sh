#!/usr/bin/env bash
# モニターモード切替スクリプト
# 使い方: monitor_mode.sh [1|2|3|single|status]

HYPR_DIR="$HOME/.config/hypr"
MODES_DIR="$HYPR_DIR/modes"
STATE_FILE="/tmp/hypr_monitor_mode"
LOCK_CMD="hyprlock"

# 全 workspace 名 (workspaces.conf と対応させること)
WORKSPACES=(shell mon term web chat AI kaggle)

# 蓋スイッチのバインドを lid.sh に復元する (switch on/off 両方)
restore_lid_binds() {
    hyprctl keyword "bindl=,switch:on:Lid Switch, exec, $HYPR_DIR/scripts/lid.sh"
    hyprctl keyword "bindl=,switch:off:Lid Switch, exec, $HYPR_DIR/scripts/lid.sh"
}

# 接続モニターが1枚だけのとき, 全 workspace をそのモニターへ集約する
apply_single() {
    # 接続中の唯一のモニター名を取得
    local mon
    mon=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].name')
    if [[ -z "$mon" || "$mon" == "null" ]]; then
        echo "エラー: 接続モニターを検出できません"
        hyprctl notify 3 3000 0 "エラー: 接続モニターを検出できません"
        return 1
    fi

    # 蓋の状態を取得
    local lid
    lid=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | awk '{print $2}' | head -1)

    # HDMI-A-1 (Dell U2718Q) は preferred が HDMI 非対応の DP 系タイミングに解決されるため
    # CEA VIC 97 の modeline を明示指定する (aquamarine 0.12 の挙動変化対策)
    local mode_token="preferred"
    if [[ "$mon" == "HDMI-A-1" ]]; then
        mode_token="modeline 594 3840 4016 4104 4400 2160 2168 2178 2250 +hsync +vsync"
    fi

    # monitors.conf を生成 (唯一のモニターを有効化, 他は wildcard で自動)
    {
        echo "monitor=$mon,$mode_token,0x0,1"
        echo "monitor=,preferred,auto,1"
        # 蓋が閉じている & 集約先が内蔵でない場合は内蔵を明示的に無効化
        # (reload や wildcard で eDP-1 が再有効化されるのを防ぐ = クラムシェル維持)
        if [[ "$lid" == "closed" && "$mon" != "eDP-1" ]]; then
            echo "monitor=eDP-1,disable"
        fi
    } > "$HYPR_DIR/monitors.conf"

    # workspaces.conf を生成 (全 workspace を唯一のモニターへバインド)
    {
        local first=1
        for ws in "${WORKSPACES[@]}"; do
            if [[ $first -eq 1 ]]; then
                echo "workspace = name:$ws, monitor:$mon, default:true"
                first=0
            else
                echo "workspace = name:$ws, monitor:$mon"
            fi
        done
    } > "$HYPR_DIR/workspaces.conf"

    # 設定を再読み込み
    hyprctl reload
    sleep 1

    # 既存 workspace を強制的に唯一のモニターへ移動
    local batch=""
    for ws in "${WORKSPACES[@]}"; do
        batch+="dispatch moveworkspacetomonitor name:$ws $mon; "
    done
    hyprctl --batch "${batch% }"

    # リッドスイッチのバインドを lid.sh に復元
    restore_lid_binds

    # 状態を保存
    echo "single" > "$STATE_FILE"

    echo "シングルモニターモード: 全 workspace を $mon に集約しました"
    hyprctl notify 1 3000 0 "シングルモニター: 全 workspace を $mon に集約"
}

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
        # モード1/3: リッドスイッチのバインドを lid.sh に復元
        restore_lid_binds
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
    single)
        apply_single
        ;;
    status)
        show_status
        ;;
    *)
        echo "使い方: $0 [1|2|3|single|status]"
        echo "  1: eDP-1 + DP-2(4K) + HDMI(縦)"
        echo "  2: DP-2(4K) + DP-1(4K) + HDMI(縦) [蓋閉じ対応]"
        echo "  3: eDP-1 + HDMI(横)"
        echo "  single: モニター1枚のみ - 全 workspace をそのモニターへ集約"
        echo "  status: 現在のモードを表示"
        exit 1
        ;;
esac
