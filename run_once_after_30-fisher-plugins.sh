#!/bin/bash
# fisher（fish プラグインマネージャ）本体を導入し、fish_plugins を同期する。
# Linux / macOS 共通。fish 導入後に 1 度だけ実行される。
set -euo pipefail

if ! command -v fish >/dev/null 2>&1; then
  echo "fish が未導入のため fisher セットアップをスキップします"
  exit 0
fi

echo "==> fisher と fish_plugins を同期します"
fish -c '
  if not functions -q fisher
    echo "==> fisher 本体を導入します"
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher install jorgebucaran/fisher
  end
  # fisher update は ~/.config/fish/fish_plugins を読んで不足分を導入・不要分を削除する
  fisher update
' || echo "WARN: fisher セットアップで問題が発生しました"
