-- tmux 環境下でのみステータスライン連携を有効化する (herdr 環境ではスキップ)
if vim.env.TMUX then
  local tmux_status = require("core.functions.tmux_toggle")
  tmux_status.toggle_tmux_status()
end
