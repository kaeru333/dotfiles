# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 概要

このリポジトリは、lazy.nvim ベースの個人用 Neovim 設定です。
fish シェル環境での使用を前提としており、起動時のパフォーマンス計測機能を含んでいます。

---

## アーキテクチャ

### ディレクトリ構成

```
~/.config/nvim/
├── init.lua                 # エントリーポイント、起動計測＋モジュール読み込み
├── lazy-lock.json           # プラグインバージョンロック
├── lua/
│   ├── core/
│   │   ├── options.lua      # vim.opt の設定（fish shell、UTF-8、indent 等）
│   │   ├── keymaps.lua      # グローバルキーマップ（Neotree、Telescope）
│   │   └── functions/
│   │       └── tmux_toggle.lua  # tmux 連携機能
│   ├── config/
│   │   ├── lazy.lua         # lazy.nvim の bootstrap と設定
│   │   └── autocmds.lua     # 自動コマンド（起動時プラグイン更新、FileType別設定等）
│   ├── plugins/             # プラグイン設定（1ファイル=1プラグイン）
│   │   ├── nvim-lspconfig.lua  # LSP設定（pyright、texlab）
│   │   ├── LuaSnip.lua         # スニペットエンジン＋ローダー
│   │   ├── snacks.lua          # 統合UI機能（dashboard、explorer、picker等）
│   │   ├── catppuccin.lua      # カラースキーム
│   │   ├── lualine.lua         # ステータスライン
│   │   ├── telescope.lua       # ファジーファインダー
│   │   ├── neotree.lua         # ファイルツリー
│   │   ├── noice.lua           # UI改善
│   │   ├── nvim-treesitter.lua # シンタックスハイライト
│   │   ├── copilot.lua         # GitHub Copilot
│   │   └── ...
│   └── snippets/
│       └── python.lua       # Python用カスタムスニペット
└── pack/                    # vim-packディレクトリ（copilot.vim、nvim-lspconfig）
```

### 初期化フロー

1. **init.lua**: `vim.loader.enable()` で Lua モジュールキャッシュ有効化
2. **core/options.lua** 読み込み: fish シェル、UTF-8、インデント設定など
3. **core/functions.lua** 読み込み: tmux 連携機能の初期化
4. **config/lazy.lua** 読み込み: lazy.nvim のブートストラップ → `lua/plugins/` 内の全ファイルを自動インポート
5. **core/keymaps.lua** 読み込み: グローバルキーマップ定義
6. **config/autocmds.lua** 読み込み: VimEnter で lazy.nvim の自動更新、外部変更の自動再読み込みなど

### プラグイン管理

- **lazy.nvim** を使用（`lua/config/lazy.lua`）
- `lua/plugins/` 内の各 `.lua` ファイルが自動で `import` される
- 各プラグイン設定は独立したファイルとして管理（例: `nvim-lspconfig.lua`、`LuaSnip.lua`）
- 起動時に自動更新が有効（`autocmds.lua:4-9`）

### LSP 構成

- **nvim-lspconfig** を使用（`lua/plugins/nvim-lspconfig.lua`）
- 設定済みサーバー:
  - **pyright**: Python LSP
  - **texlab**: LaTeX LSP（ルートディレクトリ検出: `compile.sh` or `.git`）
- cmp-nvim-lsp による補完機能統合

### スニペット構成

- **LuaSnip** を使用（`lua/plugins/LuaSnip.lua`）
- VSCode形式のスニペット（`rafamadriz/friendly-snippets`）を自動ロード
- カスタムスニペット: `lua/snippets/` から Lua形式で読み込み
- キーマップ:
  - `<C-k>`: 展開 or 次のフィールドへジャンプ
  - `<C-j>`: 前のフィールドへジャンプ
  - `<C-l>`: 選択肢変更

---

## 主要な設定

### リーダーキー

- **Leader**: `<Space>`
- **LocalLeader**: `\`

### 重要なキーマップ（`core/keymaps.lua`）

- `<Leader>t`: Neotree トグル
- `<Leader>f`: Telescope でファイル検索
- `<Leader>s`: Telescope でライブ grep

### シェル設定

- デフォルトシェル: **fish**
- `shellcmdflag = "-ic"` により対話的モードで起動
- 外部コマンド実行時に fish の設定が読み込まれる

### パフォーマンス計測

- 環境変数 `LOGFILE` が設定されている場合、起動時間を計測し該当ファイルに追記
- 環境変数 `WARMUP` が設定されている場合、Dashboard表示後に自動終了

---

## プラグイン追加時の指針

1. `lua/plugins/` 内に新規 `.lua` ファイルを作成
2. lazy.nvim 形式で return { ... } 形式で記述
3. 必要に応じて `dependencies` や `config` を定義
4. VimEnter 時に自動更新されるため、手動の `:Lazy sync` は不要

## LSP サーバー追加時の指針

1. `lua/plugins/nvim-lspconfig.lua` の `config` 関数内に追加
2. `lspconfig.<server_name>.setup({ capabilities = capabilities })` の形式で記述
3. 必要に応じて `root_dir`、`init_options`、`cmd` を設定

## 注意事項

- **fish シェル依存**: 外部コマンド実行は fish が前提
- **自動プラグイン更新**: 起動時に自動で lazy.nvim が更新される（`autocmds.lua:4-9`）
- **pack/ ディレクトリ**: copilot.vim と nvim-lspconfig が vim-pack形式で配置されている
