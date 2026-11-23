#!/usr/bin/env bash
# モニターモード切替スクリプト
# 使い方: monitor_mode.sh [1|2|3|single|status]

HYPR_DIR="$HOME/.config/hypr"
MODES_DIR="$HYPR_DIR/modes"
STATE_FILE="/tmp/hypr_monitor_mode"
LOCK_CMD="hyprlock"

# 全 workspace 名 (workspaces.conf と対応させること)
WORKSPACES=(shell mon term web chat AI kaggle)

# Dell U2718Q 用の壁紙.
# この 1 台だけ接続ポートでコネクタ名が変わる (HDMI 直挿しなら HDMI-A-1,
# type-C 変換経由なら DP-2) ため, hyprpaper.conf のコネクタ名指定では
# type-C 経由のときに DP-2 用 (Eizo EV3285) の壁紙が付いてしまう.
# hyprpaper 0.8.4 の desc: 指定は使えない
# (フル記述は rc=0 だが無反応, 前方一致は Invalid monitor) ので,
# restart_wallpaper() が EDID 記述からコネクタ名を解決して上書きする.
DELL_U2718Q_WALLPAPER="$HOME/Pictures/wallpaper/line_art_v2_4x/20260513_171601_line_art_4x.png"
DELL_U2718Q_DESC_PREFIX="Dell Inc. DELL U2718Q"

# レイアウト確定後に hyprpaper を再起動する.
# hyprpaper はレイヤーサーフェス作成時のモニター原点を保持し続けるため,
# hyprctl reload でモニター位置を組み替えても追従せず, 壁紙が旧原点のままずれる.
# 例: 単一モニター状態から DP-2 を挿すと catch-all の auto で一旦 (1920,0) に置かれ,
#     その約 1 秒後に mode1 が (0,0) へ移すが, 壁紙は 1920px 右にずれたままになる.
# hyprpaper.service は enable されず hyprland.conf から明示 start されるので,
# is-enabled ではなくユニットの存在で判定する.
restart_wallpaper() {
    systemctl --user cat hyprpaper.service >/dev/null 2>&1 || return 0
    systemctl --user restart hyprpaper.service

    # IPC が応答するまで待つ (実測 200ms 程度, 上限 5 秒)
    local i
    for ((i = 0; i < 50; i++)); do
        hyprctl hyprpaper listactive >/dev/null 2>&1 && break
        sleep 0.1
    done

    # Dell U2718Q が居るコネクタを EDID 記述から解決し, 専用の壁紙を貼る
    local name
    while read -r name; do
        [[ -n "$name" ]] || continue
        hyprctl hyprpaper preload "$DELL_U2718Q_WALLPAPER" >/dev/null
        hyprctl hyprpaper wallpaper "$name,$DELL_U2718Q_WALLPAPER" >/dev/null
    done < <(hyprctl monitors -j 2>/dev/null \
        | jq -r --arg p "$DELL_U2718Q_DESC_PREFIX" \
            '.[] | select(.description | startswith($p)) | .name')
}

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
        # 起動直後の認識タイミング等で 0 件になる場合は eDP-1 を
        # ランタイムで強制有効化してから再取得するフォールバック
        echo "警告: 接続モニターを検出できません．eDP-1 を強制有効化します"
        hyprctl notify 2 3000 0 "警告: 接続モニターなし．eDP-1 を強制有効化"
        hyprctl keyword monitor "eDP-1,preferred,auto,1"
        sleep 1
        mon=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].name')
        if [[ -z "$mon" || "$mon" == "null" ]]; then
            echo "エラー: eDP-1 強制有効化後も接続モニターを検出できません"
            hyprctl notify 3 3000 0 "エラー: eDP-1 強制有効化後も検出できません"
            return 1
        fi
    fi

    # 蓋の状態を取得
    local lid
    lid=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | awk '{print $2}' | head -1)

    # 接続モニタが Dell U2718Q のときだけ CEA VIC 97 の modeline を使う．
    # (aquamarine 0.12 の preferred 解決回帰で U2718Q が HDMI 非対応タイミングに落ちる対策)
    # それ以外 (自宅の DELL S2721HN 等) は preferred で表示する．
    local mon_desc
    mon_desc=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].description')
    local mode_token="preferred"
    if [[ "$mon_desc" == "Dell Inc. DELL U2718Q"* ]]; then
        mode_token="modeline 594 3840 4016 4104 4400 2160 2168 2178 2250 +hsync +vsync"
    fi

    # monitors.conf を生成 (唯一のモニターを有効化, 他は wildcard で自動)
    # 不変条件: 永続ファイルには monitor=eDP-1,disable を書かない
    # (起動時に読まれた際, 外部モニター未接続だと有効モニター 0 枚になるため)．
    # クラムシェル時の内蔵無効化は reload 後にランタイム keyword でのみ行う．
    {
        echo "monitor=$mon,$mode_token,0x0,1"
        echo "monitor=,preferred,auto,1"
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

    # 蓋が閉じている & 集約先が内蔵でない場合は内蔵をランタイムで無効化
    # (reload 直後は monitors.conf 再読込で eDP-1 が有効な状態なので, reload の後に打つ)
    if [[ "$lid" == "closed" && "$mon" != "eDP-1" ]]; then
        hyprctl keyword monitor "eDP-1,disable"
    fi

    # 既存 workspace を強制的に唯一のモニターへ移動
    local batch=""
    for ws in "${WORKSPACES[@]}"; do
        batch+="dispatch moveworkspacetomonitor name:$ws $mon; "
    done
    hyprctl --batch "${batch% }"

    # リッドスイッチのバインドを lid.sh に復元
    restore_lid_binds

    # レイアウト確定後に壁紙を貼り直す
    restart_wallpaper

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

    # モード2 (蓋閉じクラムシェル運用) は内蔵をランタイムで無効化する
    # (永続ファイルには書かず, reload で有効に戻った直後に keyword で適用する)
    if [[ "$mode" == "2" ]]; then
        hyprctl keyword monitor "eDP-1,disable"
    fi

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

    # レイアウト確定後に壁紙を貼り直す
    restart_wallpaper

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
