# macOS セットアップ / 移行ガイド

このリポジトリ（[kaeru333/dotfiles](https://github.com/kaeru333/dotfiles)）を使って、
**新しい Mac をほぼワンコマンドでこの環境に復元**するための手順書です。
Linux 側の話は [README.md](README.md) を参照してください。

- 管理: [chezmoi](https://www.chezmoi.io/)（`~/.local/share/chezmoi` がソース）
- アプリ / CLI: [Homebrew](https://brew.sh/) + `Brewfile`（`brew bundle` で一括導入）
- 秘密情報: [Bitwarden](https://bitwarden.com/) から注入（リポジトリには含めない）

> **TL;DR** — 新しい Mac で以下 3 行。あとは自動で dotfiles 展開 + アプリ導入 + 初期化まで走ります。
> ```bash
> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
> eval "$(/opt/homebrew/bin/brew shellenv)"; brew install chezmoi
> chezmoi init --apply kaeru333/dotfiles
> ```

---

## 1. クイックスタート（新しい Mac をこの環境にする）

### 手順

```bash
# --- (0) Xcode Command Line Tools ---
# Homebrew インストーラが自動で入れてくれるので通常は不要。
# 手動で先に入れるなら:  xcode-select --install

# --- (1) Homebrew を導入 ---
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# 現在のシェルに brew を通す（Apple Silicon は /opt/homebrew）
eval "$(/opt/homebrew/bin/brew shellenv)"

# --- (2) chezmoi を導入 ---
brew install chezmoi

# --- (3)（任意）秘密情報も復元するなら先に Bitwarden を unlock ---
#   これをやっておくと git identity / Slack / Kaggle トークンが自動注入される。
#   スキップしても後から入れられる（→ 3章）。
# brew install bitwarden-cli
# bw login            # 初回のみ
# export BW_SESSION=$(bw unlock --raw)

# --- (4) これだけ。以降は全部自動 ---
chezmoi init --apply kaeru333/dotfiles
```

`chezmoi init` の途中で `Use Bitwarden CLI to inject secrets?` と聞かれます。

- **Bitwarden を unlock 済み** → `y`（推奨。秘密情報が自動で入る）
- **使わない** → `n` を選ぶと、代わりに git の `name` / `email` を対話入力

### `chezmoi apply` が自動実行するもの

`.chezmoi.os` で macOS のみ判定して走ります（Linux では空描画されスキップ）。

| 順序 | スクリプト | 内容 |
|------|-----------|------|
| before 10 | `install-homebrew` | Homebrew 未導入なら導入 |
| after 20 | `brew-bundle` | `~/.config/homebrew/Brewfile` を適用（CLI / アプリ / フォント / VSCode 拡張 / uv / npm） |
| after 30 | `fisher-plugins` | fisher 本体 + `fish_plugins` を同期 |
| after 40 | `tmux-tpm` | tpm を clone し tmux プラグインを導入 |
| after 50 | `macos-postinstall` | sketchybar / borders をサービス起動、AeroSpace 起動、SKK-JISYO.L 取得 |
| onchange 60 | `macos-defaults` | Dock / Finder / キーボード等の `defaults` を適用 |

> 各スクリプトは失敗しても全体を止めません（`brew bundle` の一部失敗などは後で再試行可能）。
> やり直したいときは `chezmoi state delete-bucket --bucket=scriptState` で run_once の実行履歴を消せます。

---

## 2. Homebrew でアプリ / CLI を完全再現する（Brewfile）

`~/.config/homebrew/Brewfile`（ソース: `private_dot_config/homebrew/Brewfile`）に
**tap / brew / cask / VSCode 拡張 / uv ツール / npm グローバル**を宣言的にまとめています。
新しい Mac ではこの 1 ファイルからアプリ環境がまるごと復元されます。

```bash
# 手動で今すぐ適用（chezmoi apply でも自動実行される）
brew bundle --file=~/.config/homebrew/Brewfile

# 過不足チェック（インストール漏れ / 更新漏れを一覧）
brew bundle check --verbose --file=~/.config/homebrew/Brewfile

# Brewfile に無いものを一掃（棚卸し。実行前に必ず内容確認）
brew bundle cleanup --file=~/.config/homebrew/Brewfile
```

### 新しくアプリを入れたら Brewfile に反映する

このリポジトリの Brewfile は**カテゴリ別にコメントを付けて手動管理**しています。
生の `brew bundle dump` で上書きするとコメントと分類が消えるので、**差分だけ手で追記**するのが推奨です。

```bash
# 1) 現状を一時ファイルにダンプして差分を見る
brew bundle dump --force --file=/tmp/Brewfile.new
diff <(grep -E '^(brew|cask|tap|vscode) ' ~/.config/homebrew/Brewfile | sort) \
     <(grep -E '^(brew|cask|tap|vscode) ' /tmp/Brewfile.new | sort)

# 2) 追加分を chezmoi のソース Brewfile へ手で書き足す
chezmoi edit ~/.config/homebrew/Brewfile

# 3) リポジトリへ反映
chezmoi cd
git add private_dot_config/homebrew/Brewfile
git commit -m "chore(brew): add <package>"
git push
```

> **uv / npm について** — `uv "ruff"` や `npm "vim-language-server"` の行は
> Homebrew Bundle がネイティブ対応しており（`--uv` / `--npm`）、`brew bundle` 実行時に
> `uv tool install` / `npm install -g` が走ります。ただし `brew bundle dump` は既定でこれらを
> **出力しない**ため、uv ツール・npm グローバルは手動で Brewfile に追記してください。
> 現在の一覧は `uv tool list` / `npm ls -g --depth=0` で確認できます。
>
> **App Store アプリ（mas）** — 現状 mas 管理アプリはありません。使う場合は Brewfile に
> `brew "mas"` を有効化し `mas "アプリ名", id: 1234567890` を追記します（id は `mas list` で確認）。

---

## 3. 手動が必要なステップ（自動化できないもの）

`chezmoi apply` 後、以下だけは手作業が必要です。

| 項目 | 手順 |
|------|------|
| **karabiner の権限** | システム設定 → プライバシーとセキュリティ → **入力監視** で karabiner_grabber / karabiner を許可。 |
| **AquaSKK 入力ソース** | システム設定 → キーボード → 入力ソース に **AquaSKK** を追加（keymap / 辞書設定は復元済み。巨大辞書 SKK-JISYO.L は run_once が自動 DL）。 |
| **Raycast 設定** | Raycast は設定が暗号化 DB のためファイル管理不可。旧 Mac で `Raycast → Settings → Advanced → Export` し、生成された `.rayconfig` を新 Mac で Import。 |
| **Bitwarden 秘密情報** | 未注入なら `set -gx BW_SESSION (bw unlock --raw); chezmoi apply` で git identity / Slack / Kaggle を注入。 |
| **ログイン項目 / 権限** | AeroSpace・sketchybar のアクセシビリティ許可、スクリーン録画許可などを初回起動時のダイアログで許可。 |

秘密情報（git identity / Slack / Kaggle）は **Bitwarden 未導入・未 unlock でもエラーにならず自動スキップ**されます。
後から `bw unlock` して `chezmoi apply` を再実行すれば注入されます。

---

## 4. 旧 Mac → 新 Mac の移行チェックリスト

「環境をまるごと引っ越す」ときの流れ。**リポジトリ自体が環境のスナップショット**なので、
旧マシンで最新化して push → 新マシンで復元、が基本です。

### 旧 Mac でやること（引っ越し前に最新化）

```bash
chezmoi cd    # = ~/.local/share/chezmoi

# 1) 変更した設定ファイルをソースへ取り込む（差分を確認してから）
chezmoi re-add            # 管理下ファイルの変更を取り込む
chezmoi status            # 取り込み漏れ / 差分を確認
#   ※ .gitconfig / secrets.fish 等の秘密テンプレートは自動でスキップされる

# 2) Brewfile を最新化（→ 2章の手順で差分追記）

# 3) コミットして push
git add -A && git commit -m "chore: snapshot before migration" && git push
```

そのほか手動で退避するもの:

- **Raycast**: Settings → Advanced → Export で `.rayconfig` を書き出して保管。
- **秘密情報**: すでに Bitwarden にあるので追加作業は不要（無ければ Bitwarden に登録）。
- **アプリ個別のライセンス / ログイン**: Office・Slack 等はサインインし直し。

### 新 Mac でやること

1. [1章](#1-クイックスタート新しい-mac-をこの環境にする) のクイックスタートを実行。
2. [3章](#3-手動が必要なステップ自動化できないもの) の手動ステップ（Raycast import・各種権限）を実施。
3. 動作確認: `fish` が既定シェルか、`nvim`・`tmux`・AeroSpace・sketchybar が起動するか。

---

## 5. 日々のメンテナンス

```bash
# 設定を編集する（ソースを直接編集 → apply）
chezmoi edit ~/.config/fish/config.fish
chezmoi apply

# 逆に、~/.config を直接いじった後にソースへ取り込む
chezmoi re-add ~/.config/fish/config.fish

# ソースの git 操作
chezmoi cd
git add -A && git commit -m "..." && git push

# リモートの更新を取り込む
chezmoi update            # = git pull + apply
```

> **秘密情報の再混入に注意** — `~/.config/fish/config.fish` などには AWS プロファイルや
> 個人パスが含まれることがあります。**公開リポジトリ**なので、`chezmoi re-add` で取り込む前に
> 差分（`chezmoi diff`）を必ず確認し、秘匿値を含めないでください。git identity や Slack/Kaggle
> トークンは `.tmpl` として Bitwarden 参照になっており、`re-add` の対象外です。

---

## 6. トラブルシュート

| 症状 | 対処 |
|------|------|
| `brew` が見つからない | `eval "$(/opt/homebrew/bin/brew shellenv)"` を実行。fish なら再ログインで `conf.d` が通す。 |
| `brew bundle` が一部失敗 | ネットワーク / cask の一時的失敗が多い。`brew bundle --file=~/.config/homebrew/Brewfile` を再実行。 |
| run_once が走らない / もう一度走らせたい | `chezmoi state delete-bucket --bucket=scriptState` の後 `chezmoi apply`。 |
| 日本語入力の候補が Ctrl+N/P で動かない | karabiner の入力監視権限を確認（→ 3章）。Firefox 向けの素通しルールは karabiner.json に定義済み。 |
| SKK-JISYO.L が無い | `chezmoi apply` を再実行するか、AquaSKK 環境設定から手動で辞書を追加。 |
| chezmoi の設定を作り直したい | `chezmoi init`（`~/.config/chezmoi/chezmoi.toml` を再生成）。 |

---

各コンポーネント（WM / バー / エディタ等）の対応表と Linux 側の手順は
[README.md](README.md) を参照してください。
