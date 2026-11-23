return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    -- カラースキームは遅延させず起動時に適用する (lazy.nvim の推奨)
    lazy = false,
    priority = 1000,
    config = function()
      -- flavour (latte/mocha) ・透過・カスタムハイライトは core.theme が持つ．
      -- nvim 0.12 から本体同梱の "catppuccin" と名前が衝突するため，
      -- core.theme 側でプラグインのフレーバー名を明示している (同梱版は transparent 非対応)
      require("core.theme").setup()
    end,
  },
}
