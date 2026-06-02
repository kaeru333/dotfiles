#!/bin/bash
# tpm（tmux plugin manager）を clone し、tmux.conf の @plugin を一括導入する。
# Linux / macOS 共通。tmux 導入後に 1 度だけ実行される。
set -euo pipefail

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux が未導入のため tpm セットアップをスキップします"
  exit 0
fi

TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo "==> tpm を clone します"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

echo "==> tmux プラグインをインストールします"
"$TPM_DIR/bin/install_plugins" || echo "WARN: tpm プラグイン導入で問題が発生しました"
