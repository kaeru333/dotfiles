# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

Fish shell の設定ファイル群。プラグイン管理に Fisher を使用し、テーマは bobthefish を採用している。

## ディレクトリ構成

- `config.fish` - メインの設定ファイル。環境変数、PATH、tmux 自動起動などを定義
- `abbr/abbr.fish` - 省略形 (abbreviations) の定義。`config.fish` から source される
- `myconf.d/bobthefish.fish` - bobthefish テーマの設定。`config.fish` から source される
- `conf.d/` - 自動読み込みされる設定ファイル (fzf, z, nvm, fnm など)
- `functions/` - カスタム関数の定義
- `completions/` - コマンド補完の定義
- `fish_plugins` - Fisher で管理するプラグインリスト

## 使用プラグイン (Fisher)

- **oh-my-fish/theme-bobthefish** - プロンプトテーマ
- **jethrokuan/z** - ディレクトリジャンプ (`z` コマンド)
- **jorgebucaran/nvm.fish** - Node.js バージョン管理
- **jethrokuan/fzf** - ファジーファインダー統合

## よく使うコマンド

```fish
# プラグイン管理
fisher install <plugin>    # プラグイン追加
fisher update              # プラグイン更新
fisher list                # インストール済みプラグイン一覧

# 設定の再読み込み
source ~/.config/fish/config.fish

# 関数の定義確認
functions <function_name>

# 省略形の確認
abbr --show
```

## カスタム関数

- `mkcd <dir>` - ディレクトリ作成後、そこに移動
- `trash <file>` - ファイルを `~/.trash` に移動 (タイムスタンプ付き)
- `submit` - AtCoder 用提出コマンド (acc + pypy)
- `md_to_pdf <input.md> <output.pdf>` - Pandoc + LuaLaTeX で日本語対応 PDF 変換

## 主要な省略形

- `vi` -> `nvim`
- `ls` -> `eza --icons --color`
- `cat` -> `bat`
- `...` -> `../..` (任意の位置で展開可能)
- `cc` -> `claude --dangerously-skip-permissions`
- `te` -> `trans -b :en` (日→英翻訳)
- `tj` -> `trans -b :ja` (英→日翻訳)
- `Te` -> `| trans -b :en` (パイプ版、任意の位置で展開可能)
- `Tj` -> `| trans -b :ja` (パイプ版、任意の位置で展開可能)
- `C` -> `| wl-copy` (任意の位置で展開可能)
- `G` -> `| grep` (任意の位置で展開可能)

## FZF キーバインド

- `Ctrl+T` - ファイル検索
- `Ctrl+R` - コマンド履歴検索
- `Alt+C` - ディレクトリ移動
- `Alt+Shift+C` - 隠しファイル含むディレクトリ移動

## 注意事項

- `config.fish` にはキャッシュ機構があり、`$FISH_CACHE_DIR/config.fish` に動的設定をキャッシュする
- tmux の自動起動が設定されており、インタラクティブシェル起動時に既存セッションにアタッチまたは新規作成する
- Wayland 環境変数の自動検出機能あり
