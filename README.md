# dotfiles

Linux (EndeavourOS / Hyprland) と macOS (AeroSpace) の個人環境設定。
fish / tmux / Neovim / 各種ターミナルは両 OS で共有し、ウィンドウマネージャ等の OS 固有設定は
`.chezmoiignore` 内で `.chezmoi.os` により振り分けて、**同一リポジトリで両 OS に対応**しています。
[chezmoi](https://www.chezmoi.io/) で管理、[Bitwarden](https://bitwarden.com/) と連携して秘密情報を分離。

## Bootstrap（新マシンへの導入）

### Linux

```bash
# 1. Bitwarden CLI をインストールしてアンロック（秘密情報が必要な場合）
yay -S bitwarden-cli
export BW_SESSION=$(bw login --raw)   # 初回
# または
export BW_SESSION=$(bw unlock --raw)  # 2 回目以降

# 2. chezmoi で一発セットアップ
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kaeru333/dotfiles
```

### macOS（ほぼワンコマンド復元）

> 📖 **詳しい手順・移行チェックリストは [README-macos.md](README-macos.md) を参照。**
> 新しい Mac のセットアップ、Brewfile 運用、旧 Mac からの移行はこちらにまとめています。

```bash
# 1. Homebrew と chezmoi を導入（chezmoi が以降の依存を全部入れる）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install chezmoi

# （任意）秘密情報も復元する場合は先に Bitwarden CLI を unlock
# brew install bitwarden-cli && set -gx BW_SESSION (bw unlock --raw)

# 2. これだけ。dotfiles 展開 + アプリ導入 + 各種初期化まで自動実行される
chezmoi init --apply kaeru333/dotfiles
```

`chezmoi apply` が以下の `run_` スクリプトを順に自動実行します（macOS 専用は `.chezmoi.os` で判定、Linux では空描画されスキップ）:

| 順序 | スクリプト | 内容 |
|------|-----------|------|
| before 10 | `install-homebrew` | Homebrew 未導入なら導入 |
| after 20 | `brew-bundle` | `~/.config/homebrew/Brewfile` を適用（アプリ/CLI/フォント/VSCode拡張/uv/npm） |
| after 30 | `fisher-plugins` | fisher 本体 + `fish_plugins` を同期 |
| after 40 | `tmux-tpm` | tpm を clone し tmux プラグインを導入 |
| after 50 | `macos-postinstall` | sketchybar/borders をサービス起動、AeroSpace 起動、SKK-JISYO.L 取得 |
| onchange 60 | `macos-defaults` | Dock/Finder/キーボード等の `defaults` を適用 |

> 秘密情報（git identity / Slack / Kaggle）は **bw 未導入・未 unlock でもエラーにならず自動スキップ**されます。
> 後から `bw unlock` して `chezmoi apply` を再実行すれば注入されます。

#### Brewfile の保守

```bash
# 現状をダンプして差分を確認（Brewfile はカテゴリ別コメント付きで手動管理）
brew bundle dump --force --file=/tmp/Brewfile.new
diff <(grep -E '^(brew|cask|tap|vscode) ' ~/.config/homebrew/Brewfile | sort) \
     <(grep -E '^(brew|cask|tap|vscode) ' /tmp/Brewfile.new | sort)
chezmoi edit ~/.config/homebrew/Brewfile    # 追加分を手で追記 → コミット
# Brewfile 未記載のものを一掃したいとき
brew bundle cleanup --file=~/.config/homebrew/Brewfile
```

> 詳しい Brewfile 運用（uv / npm / mas の扱い含む）は [README-macos.md](README-macos.md#2-homebrew-でアプリ--cli-を完全再現するbrewfile) を参照。

## Environment

| ツール | Linux | macOS |
|--------|-------|-------|
| OS | EndeavourOS (Arch Linux) | macOS |
| WM | Hyprland (Wayland) | AeroSpace |
| バー | waybar | sketchybar |
| ウィンドウ枠 | — | borders (JankyBorders) |
| ランチャー | rofi | Raycast |
| 通知 | dunst | — |
| キーリマップ | xremap | karabiner |
| Shell | fish | fish |
| Terminal | foot / wezterm | alacritty / ghostty / wezterm |
| Editor | Neovim (lazy.nvim) | Neovim (lazy.nvim) |
| Multiplexer | tmux (tpm) | tmux (tpm) |

## Structure

OS 固有のディレクトリは `.chezmoiignore`（`.chezmoi.os` 分岐）で、適用先 OS に合うものだけが展開されます。

```
~/
├── .gitconfig          ← git（name/email は Bitwarden 注入）
├── .latexmkrc          ← LaTeX ビルド設定
└── .config/
    │  # --- 共有（両 OS）---
    ├── nvim/           ← Neovim (lazy.nvim)
    ├── fish/           ← fish shell + abbreviations + functions
    ├── tmux/           ← tmux（plugins は tpm が管理）
    ├── wezterm/        ← ターミナルエミュレータ
    ├── alacritty/      ← ターミナルエミュレータ
    ├── ghostty/        ← ターミナルエミュレータ
    ├── lazygit/        ← Git TUI
    │  # --- Linux 専用 ---
    ├── hypr/           ← Hyprland
    ├── waybar/         ← ステータスバー
    ├── wlogout/        ← ログアウト画面
    ├── rofi/           ← アプリランチャー
    ├── dunst/          ← 通知デーモン
    ├── foot/           ← ターミナルエミュレータ
    ├── zathura/        ← PDF ビューア
    │  # --- macOS 専用 ---
    ├── homebrew/       ← Brewfile（brew bundle で一括導入）
    ├── aerospace/      ← AeroSpace（タイル型 WM）
    ├── sketchybar/     ← ステータスバー
    ├── borders/        ← ウィンドウ枠（JankyBorders）
    ├── karabiner/      ← キーリマップ
    └── ...
~/Library/                      # macOS 専用
└── Application Support/AquaSKK/ ← 日本語入力 SKK（keymap.conf 等。巨大辞書は除外）
```

## Secrets

秘密情報はリポジトリに含まれません。

| 情報 | 管理方法 |
|------|---------|
| git メール / 名前 | Bitwarden `chezmoi/identity` |
| Slack トークン / Webhook | Bitwarden `chezmoi/slack-secrets` |
| Kaggle API トークン | Bitwarden `chezmoi/kaggle` |
| SSH 鍵 / GPG | `.chezmoiignore` で除外 |
| Overleaf セッション | `.chezmoiignore` で除外 |

## macOS の手動ステップ（自動化できないもの）

`chezmoi apply` 後に、以下だけは手動が必要です。

| 項目 | 手順 |
|------|------|
| **Raycast 設定** | Raycast は設定が暗号化 DB のためファイル管理不可。旧マシンで `Raycast → Settings → Advanced → Export` し、生成された `.rayconfig` を新マシンで Import する。 |
| **karabiner 権限** | システム設定 → プライバシーとセキュリティ → 入力監視 で karabiner を許可。 |
| **AquaSKK 入力ソース** | システム設定 → キーボード → 入力ソース に AquaSKK を追加（辞書/キーマップは復元済み）。 |
| **Bitwarden 秘密情報** | `set -gx BW_SESSION (bw unlock --raw); chezmoi apply` で git identity / Slack / Kaggle を注入。 |
| **App Store アプリ** | `mas` は未管理。必要なら Brewfile に `brew "mas"` と `mas "App名", id:...` を追記。 |

## Migrated from（アーカイブ済み旧リポ）

| 旧リポ | 最終コミット |
|--------|------------|
| [kaeru333/hypr](https://github.com/kaeru333/hypr) | 67158fa |
| [kaeru333/kaeru_nvim_config](https://github.com/kaeru333/kaeru_nvim_config) | eecc16d |
| [kaeru333/kaeru_fish_config](https://github.com/kaeru333/kaeru_fish_config) | 5cb4466 |
| [kaeru333/my_tmux_config](https://github.com/kaeru333/my_tmux_config) | efaf191 |

## Credits

- `dot_config/wlogout/` — [catppuccin/wlogout](https://github.com/catppuccin/wlogout) からの clone（MIT ライセンス、詳細は [THIRDPARTY.md](private_dot_config/wlogout/THIRDPARTY.md) を参照）

## License

MIT（`dot_config/wlogout/` 配下は上流ライセンスに従う）
