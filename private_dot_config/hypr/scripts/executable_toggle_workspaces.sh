#!/bin/bash
# ワークスペース "shell" と "term" をモニター間でトグルするスクリプト

current_workspace=$(hyprctl activeworkspace -j | jq -r '.name')

# 現在のワークスペース情報を動的に取得
shell_monitor=$(hyprctl workspaces -j | jq -r '.[] | select(.name == "shell") | .monitor')
term_monitor=$(hyprctl workspaces -j | jq -r '.[] | select(.name == "term") | .monitor')

# ワークスペースが存在しない場合は何もしない
if [ -z "$shell_monitor" ] || [ -z "$term_monitor" ]; then
    echo "エラー: shell または term ワークスペースが見つかりません"
    exit 1
fi

# 同じモニターにいる場合は入れ替えできない
if [ "$shell_monitor" = "$term_monitor" ]; then
    echo "エラー: shell と term が同じモニター ($shell_monitor) にあります"
    exit 1
fi

# shell と term のモニターを入れ替え
hyprctl dispatch moveworkspacetomonitor "name:shell $term_monitor"
hyprctl dispatch moveworkspacetomonitor "name:term $shell_monitor"

# トグル後のフォーカス処理
# shell/term にいた場合は、入れ替わった相手にフォーカス
if [[ "$current_workspace" == "shell" ]]; then
    hyprctl dispatch workspace name:term
elif [[ "$current_workspace" == "term" ]]; then
    hyprctl dispatch workspace name:shell
else
    hyprctl dispatch workspace "name:$current_workspace"
fi
