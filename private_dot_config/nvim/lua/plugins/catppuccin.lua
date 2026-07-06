return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    -- カラースキームは遅延させず起動時に適用する (lazy.nvim の推奨)
    lazy = false,
    priority = 1000,
    opts = {
      transparent_background = true,
      -- treesitter の細かい色分けを抑え, 以前の Vim 標準シンタックスに近いシンプルな見た目にする
      custom_highlights = function(colors)
        return {
          -- 変数系はすべてテキスト色に統一（オレンジ/白が混在しないように）
          ["@variable"] = { fg = colors.text },
          ["@variable.parameter"] = { fg = colors.text },
          ["@variable.member"] = { fg = colors.text },
          ["@property"] = { fg = colors.text },
          ["@field"] = { fg = colors.text },
          -- self/cls などの組み込み変数のみ控えめに着色
          ["@variable.builtin"] = { fg = colors.red },
          -- 関数は宣言・呼び出し・メソッドをすべて同色に統一
          ["@function"] = { fg = colors.blue },
          ["@function.call"] = { fg = colors.blue },
          ["@function.method"] = { fg = colors.blue },
          ["@function.method.call"] = { fg = colors.blue },
          ["@constructor"] = { fg = colors.blue },
        }
      end,
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      -- nvim 0.12 から本体同梱の "catppuccin" と名前が衝突するため，
      -- プラグイン側のフレーバー名を明示する (同梱版は transparent 非対応)
      vim.cmd.colorscheme("catppuccin-mocha")
      vim.api.nvim_set_hl(0, "CursorLine", { bg = "NONE", sp = "#4c6a8c", underline = true})
      vim.api.nvim_set_hl(0, "CursorColumn", { bg = "NONE", underline = true, sp = "#4c6a8c"})
    end,
  },
}
