return {
  "rcarriga/nvim-notify",
  event = "VeryLazy",
  opts = {
    -- エラーを修正するため、具体的な色コードを指定する
    background_colour = "#000000",

    -- 以下は以前の設定例です。お好みに合わせて調整してください。
    timeout = 3000,
    win_options = {
      winblend = 30,
    },
    -- その他の設定...
  },
  -- config function は不要です
}
