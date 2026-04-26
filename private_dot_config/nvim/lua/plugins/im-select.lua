-- fcitx5-skk との連携は lua/config/autocmds.lua のカスタム autocmd で実装済み。
-- (InsertLeave/CmdlineLeave 時に fcitx5-remote -c で半角に戻す)
return {
  "keaising/im-select.nvim",
  enabled = false,
}
