return {
  {
    "glacambre/firenvim",
    -- 拡張機能との連携のためにビルド時にインストールコマンドを実行
    build = ":call firenvim#install(0)",
    -- Firenvimが起動している時のみ即座に読み込む
    lazy = not vim.g.started_by_firenvim,
    config = function()
      -- Firenvim環境下の設定
      if vim.g.started_by_firenvim == true then
        -- 1. UIの簡素化（狭いテキストエリアで見やすくするため）
        vim.o.laststatus = 0 -- ステータスラインを非表示
        vim.o.showtabline = 0 -- タブラインを非表示
        vim.o.ruler = false
        vim.o.showcmd = false
        vim.o.number = false -- 行番号も不要ならfalse
        vim.o.relativenumber = false

        -- フォントサイズを少し大きくするとブラウザで見やすい（環境によります）
        vim.o.guifont = "Monospace:h12"

        -- 2. Firenvim固有の設定
        vim.g.firenvim_config = {
          localSettings = {
            [".*"] = {
              -- "always": 常に有効化
              -- "never": <C-e>などを押した時だけ有効化
              takeover = "never",
              cmdline = "firenvim",
            },
          },
        }

        -- 3. 背景を透明にしてブラウザの色を活かす
        vim.cmd("highlight Normal guibg=NONE")
        vim.cmd("highlight NormalNC guibg=NONE")
        vim.cmd("highlight EndOfBuffer guibg=NONE")

        -- 4. 入力完了・キャンセルのキーマップ
        -- <C-z> で保存してブラウザに戻る
        vim.keymap.set({"n", "i"}, "<C-z>", "<cmd>w<cr><cmd>call firenvim#hide_frame()<cr>", { desc = "Save & Hide" })
        -- <C-c> で保存せずに閉じる
        vim.keymap.set("n", "<C-c>", "<cmd>call firenvim#hide_frame()<cr>", { desc = "Hide" })
      end
    end,
  },
  
  -- 【推奨】Firenvim起動時は重いUIプラグインを無効化する
  {
    "folke/noice.nvim",
    enabled = not vim.g.started_by_firenvim,
  },
  {
    "nvim-lualine/lualine.nvim",
    enabled = not vim.g.started_by_firenvim,
  },
  {
    "folke/snacks.nvim",
    enabled = not vim.g.started_by_firenvim,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = not vim.g.started_by_firenvim,
  },
  {
    "nvim-telescope/telescope.nvim",
    enabled = not vim.g.started_by_firenvim,
  },
  {
    "akinsho/bufferline.nvim",
    enabled = not vim.g.started_by_firenvim,
  },
}
