# dotfiles

EndeavourOS / Hyprland / fish / tmux / Neovim の個人環境設定。
[chezmoi](https://www.chezmoi.io/) で管理、[Bitwarden](https://bitwarden.com/) と連携して秘密情報を分離。

## Bootstrap（新マシンへの導入）

```bash
# 1. Bitwarden CLI をインストールしてアンロック（秘密情報が必要な場合）
yay -S bitwarden-cli
export BW_SESSION=$(bw login --raw)   # 初回
# または
export BW_SESSION=$(bw unlock --raw)  # 2 回目以降

# 2. chezmoi で一発セットアップ
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kaeru333/dotfiles
```

## Environment

| ツール | 種類 |
|--------|------|
| OS | EndeavourOS (Arch Linux) |
| WM | Hyprland (Wayland) |
| Shell | fish |
| Terminal | foot / wezterm |
| Editor | Neovim (lazy.nvim) |
| Multiplexer | tmux (tpm) |

## Structure

```
~/
├── .gitconfig          ← git（name/email は Bitwarden 注入）
├── .latexmkrc          ← LaTeX ビルド設定
└── .config/
    ├── hypr/           ← Hyprland
    ├── nvim/           ← Neovim (lazy.nvim)
    ├── fish/           ← fish shell + abbreviations + functions
    ├── tmux/           ← tmux（plugins は tpm が管理）
    ├── wlogout/        ← wlogout ログアウト画面
    ├── waybar/         ← ステータスバー
    ├── rofi/           ← アプリランチャー
    ├── dunst/          ← 通知デーモン
    ├── foot/           ← ターミナルエミュレータ
    ├── wezterm/        ← ターミナルエミュレータ
    ├── lazygit/        ← Git TUI
    ├── zathura/        ← PDF ビューア
    └── ...
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
