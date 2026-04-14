# Neovim Configuration

個人用 Neovim 設定ファイル群です。lazy.nvim ベースで構成されており、fish シェル環境での使用を前提としています。Arch Linux および macOS に対応しています。

## 概要

- **プラグイン管理**: lazy.nvim
- **カラースキーム**: Catppuccin
- **LSP**: pyright (Python), texlab (LaTeX)
- **スニペット**: LuaSnip
- **補完**: nvim-cmp
- **ファイル検索**: Telescope
- **ファイルツリー**: neo-tree
- **AI補完**: GitHub Copilot

## 必要な環境

- **OS**: Arch Linux / macOS
- **Neovim**: v0.10.0 以上
- **シェル**: fish
- **Git**: コマンドライン操作用

### 推奨パッケージ

```bash
# Arch Linux
sudo pacman -S neovim fish git ripgrep fd

# macOS (Homebrew)
brew install neovim fish git ripgrep fd
```

## インストール

1. このリポジトリをクローン:

```bash
git clone git@github.com:kaeru333/kaeru_nvim_config.git ~/.config/nvim
```

2. Neovim を起動:

```bash
nvim
```

初回起動時に lazy.nvim が自動的にプラグインをインストールします。

## 主要な機能

### キーマップ

- **Leader キー**: `<Space>`
- **LocalLeader キー**: `\`

#### よく使うキーマップ

- `<Leader>t`: Neotree トグル
- `<Leader>f`: Telescope でファイル検索
- `<Leader>s`: Telescope でライブ grep

#### スニペット操作

- `<C-k>`: スニペット展開 or 次のフィールドへジャンプ
- `<C-j>`: 前のフィールドへジャンプ
- `<C-l>`: 選択肢変更

### ディレクトリ構成

```
~/.config/nvim/
├── init.lua                 # エントリーポイント
├── lazy-lock.json           # プラグインバージョンロック
├── lua/
│   ├── core/                # コア設定
│   │   ├── options.lua      # Neovim オプション
│   │   ├── keymaps.lua      # キーマップ定義
│   │   └── functions/       # カスタム関数
│   ├── config/              # プラグイン管理設定
│   │   ├── lazy.lua         # lazy.nvim 設定
│   │   └── autocmds.lua     # 自動コマンド
│   ├── plugins/             # プラグイン個別設定
│   └── snippets/            # カスタムスニペット
└── pack/                    # vim-pack ディレクトリ
```

## LSP 設定

現在設定済みの LSP サーバー:

- **pyright**: Python 言語サーバー
- **texlab**: LaTeX 言語サーバー

追加の LSP サーバーをインストールする場合は、`lua/plugins/nvim-lspconfig.lua` を編集してください。

## カスタマイズ

### プラグインの追加

`lua/plugins/` ディレクトリ内に新しい `.lua` ファイルを作成し、lazy.nvim 形式で記述してください:

```lua
return {
  "author/plugin-name",
  config = function()
    -- 設定内容
  end,
}
```

### スニペットの追加

`lua/snippets/` ディレクトリ内にファイルタイプ別の `.lua` ファイルを作成し、LuaSnip 形式でスニペットを定義してください。

## ライセンス

個人用設定ファイルのため、自由に使用・改変してください。

## 参考

- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [Neovim Documentation](https://neovim.io/doc/)
