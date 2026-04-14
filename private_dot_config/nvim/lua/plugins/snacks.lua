return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- 起動時に必要な機能のみ有効化
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    statuscolumn = { enabled = true },
    -- 以下は必要に応じて遅延ロード可能
    explorer = { enabled = false },  -- Neotreeを使用
    indent = { enabled = true },
    input = { enabled = true },
    picker = { enabled = false },  -- Telescopeを使用
    scope = { enabled = true },
    scroll = { enabled = true },
    words = { enabled = true },
  },
}
