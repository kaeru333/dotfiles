#!/usr/bin/env bash
# セーフティネット: 有効モニターが 0 枚のままブラックスクリーンになるのを防ぐ
#
# 有効モニターが 1 枚も無いと Hyprland は描画先を失い，画面が真っ暗のまま
# 操作を受け付けないように見える．こうなると電源ボタンを押すしかない．
# 有効モニターが 0 枚なら eDP-1 をランタイムで有効化して，この状態から抜ける．
# (monitors.conf 等の永続ファイルは一切変更しない)
#
# 呼ばれる場面:
#   1. Hyprland 起動直後 (exec-once)      … DRM 認識や monitors.conf 反映の遅れ対策
#   2. 蓋を開けたとき (lid.sh)            … クラムシェル解除時の取りこぼし対策
#   3. モニター増減時 (monitor_watch.sh)  … 最後の外部モニターを外したとき
#
# 有効化は一度投げて終わりにしない．蓋を開けた直後は内蔵パネルが DRM 上で
# connected に戻るまで数秒かかり，1 回では取りこぼす (2026-08-25 19:13 に発生)．
# 反映を確認しながら短く再試行する．
#
# 終了コード: 0 = 有効モニターあり / 1 = 戻せなかった

set -u

readonly INTERNAL="eDP-1"
readonly PROBE_RETRY=5      # hyprctl の応答待ち回数
readonly ENABLE_RETRY=8     # 内蔵画面の有効化を試みる回数
readonly INTERVAL=1
readonly LOG_FILE="/tmp/hypr_ensure_display.log"

log() {
    echo "[ensure_display] $(date '+%H:%M:%S') $*" | tee -a "$LOG_FILE"
}

# 有効モニター数を返す (取得できなければ空文字)
monitor_count() {
    local n
    n=$(hyprctl monitors -j 2>/dev/null | jq 'length' 2>/dev/null)
    [[ "$n" =~ ^[0-9]+$ ]] && echo "$n"
}

# hyprctl が応答するまで待つ (起動直後を想定)
count=""
for ((i = 1; i <= PROBE_RETRY; i++)); do
    count=$(monitor_count)
    [[ -n "$count" ]] && break
    log "hyprctl 応答待ち (${i}/${PROBE_RETRY})"
    sleep "$INTERVAL"
done

if [[ -z "$count" ]]; then
    log "警告: 有効モニター数を取得できませんでした．判定を中止します"
    exit 1
fi

# 通常はここで抜ける (モニター増減のたびに呼ばれるためログは出さない)
if [[ "$count" -ge 1 ]]; then
    exit 0
fi

log "有効モニター 0 枚を検出．$INTERNAL を有効化します"

for ((i = 1; i <= ENABLE_RETRY; i++)); do
    hyprctl keyword monitor "${INTERNAL},preferred,auto,1" >/dev/null 2>&1
    sleep "$INTERVAL"
    count=$(monitor_count)
    if [[ -n "$count" && "$count" -ge 1 ]]; then
        log "$INTERNAL を有効化しました (${i} 回目, 有効モニター数 ${count})"
        exit 0
    fi
done

log "$INTERNAL を有効化できませんでした — 蓋が閉じている可能性があります"
exit 1
