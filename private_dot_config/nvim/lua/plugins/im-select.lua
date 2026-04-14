return {
  "keaising/im-select.nvim",
  event = "InsertEnter",
  config = function()
    require("im_select").setup({
      -- ノーマルモード時のデフォルトIM（OS自動検出に任せる）
      -- Linux (fcitx5): "keyboard-us"
      -- macOS: "com.apple.keylayout.ABC"

      -- IME切替コマンド（OS自動検出に任せる）
      -- Linux: "fcitx5-remote"
      -- macOS: "macism"

      -- ノーマルモードに戻る時に英語に切替
      set_default_events = { "InsertLeave", "CmdlineLeave" },

      -- インサートモード復帰時にIMEを復元しない（常に英語で開始）
      set_previous_events = {},

      -- IMEコマンドが見つからない場合に警告を出さない
      keep_quiet_on_no_binary = true,
    })
  end,
}
