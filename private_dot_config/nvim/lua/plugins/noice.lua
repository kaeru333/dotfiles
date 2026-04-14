return {
  "folke/noice.nvim",
  event = "VeryLazy",
  -- !! この priority 設定が最重要 !!
  -- デフォルト(1000)より低い数値を設定し、読み込みを意図的に遅らせる
  -- これにより、他のプラグインによるUI設定をnoiceが上書きできる
  priority = 10,
  opts = {
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
}
