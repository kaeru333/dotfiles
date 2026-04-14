local M = {}
-- tmuxのステータスラインをトグルする関数
function M.toggle_tmux_status()
  -- tmuxが起動していて、neovimがGUIモードでない場合
  if vim.fn.has('gui_running') == 0 and os.getenv("TMUX") ~= nil then
    -- VimEnter と VimLeave イベントに対して処理を追加
    vim.api.nvim_create_autocmd({"VimEnter", "VimLeave"}, {
      pattern = "*",
      callback = function()
        -- tmuxのステータスラインをトグルする
        vim.fn.system("tmux set status")  -- ステータスラインをトグル
      end
    })
  end
end

return M
