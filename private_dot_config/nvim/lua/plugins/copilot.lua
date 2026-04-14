return {
  "github/copilot.vim",
  -- VeryLazy で起動直後にロード（Copilot は初期化に時間がかかるため）
  event = "VeryLazy",
  config = function()
    vim.g.copilot_no_tab_map = true
    vim.api.nvim_set_keymap("i", "<C-f>", "copilot#Accept('<CR>')", { noremap = true, silent = true, expr = true })
  end,
}

