#!/usr/bin/env bash
# cliphist クリップボード履歴を選んで，その場に貼り付けるところまで行う．
#   1. rofi を開く前に貼り付け先ウィンドウを記録する（rofi 起動後はアクティブが rofi になるため）
#   2. cliphist list を rofi で選び，wl-copy でクリップボードへ入れる
#   3. 元のウィンドウへフォーカスを戻し，貼り付けキーを送る
#
#   貼り付けキーはアプリによって異なるのでウィンドウクラスで分岐する:
#     ターミナル系 … Ctrl+Shift+V   その他 … Ctrl+V
#   ターミナルを追加したい場合は下の TERMINAL_CLASSES に app-id を足す．
#
#   キー送信には Hyprland の sendshortcut ディスパッチャを使う（0.39 以降）．
#   テキストを直接打ち込む wtype 方式と違い，画像履歴もそのまま貼り付けられる．
set -u

# 貼り付けに Ctrl+Shift+V を使うターミナルのウィンドウクラス（grep -E の選択パターン）
TERMINAL_CLASSES='foot|kitty|Alacritty|org\.wezfurlong\.wezterm|com\.mitchellh\.ghostty|xterm|URxvt'

# rofi が閉じた後にキーを送るまでの待ち時間（秒）．
# 貼り付かない／別ウィンドウに入る場合は 0.1〜0.2 へ増やす．
FOCUS_DELAY=0.05

# rofi を開く前に貼り付け先を控えておく．フォーカスが無いときは空になる．
win="$(hyprctl activewindow -j 2>/dev/null)"
addr="$(printf '%s' "$win" | jq -r '.address // ""')"
class="$(printf '%s' "$win" | jq -r '.class // ""')"

# 履歴を選択（Esc でキャンセルすると空になるので何もせず抜ける）
sel="$(cliphist list | rofi -dmenu -display-columns 2 -p "clip")"
[ -z "$sel" ] && exit 0

printf '%s' "$sel" | cliphist decode | wl-copy

# 貼り付け先が特定できなければコピーのみで終了（従来どおりの挙動）
[ -z "$addr" ] && exit 0

# rofi が閉じた後，元のウィンドウへ確実にフォーカスを戻す．
# unmap が終わる前にキーを送ると rofi 側へ流れるため少し待つ．
hyprctl dispatch focuswindow "address:$addr" >/dev/null 2>&1
sleep "$FOCUS_DELAY"

# ターミナル系は Ctrl+V が貼り付けではないので Ctrl+Shift+V を送る
if printf '%s' "$class" | grep -qE "^($TERMINAL_CLASSES)$"; then
  hyprctl dispatch sendshortcut "CTRL SHIFT, V, address:$addr" >/dev/null 2>&1
else
  hyprctl dispatch sendshortcut "CTRL, V, address:$addr" >/dev/null 2>&1
fi
