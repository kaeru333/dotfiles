return {
  "github/copilot.vim",
  -- VeryLazy で起動直後にロード（Copilot は初期化に時間がかかるため）
  event = "VeryLazy",
  init = function()
    -- fnm 環境では PATH 上の node がシェル/ディレクトリごとに別パス (fnm_multishells/<id>/bin/node) になり、
    -- macOS キーチェーンが毎回「別アプリ」と判定してパスワードを要求する。fnm の default を固定で使う
    local fnm_node = vim.fn.expand("~/.local/share/fnm/aliases/default/bin/node")
    if vim.fn.executable(fnm_node) == 1 then
      vim.g.copilot_node_command = fnm_node
    end
  end,
  config = function()
    vim.g.copilot_no_tab_map = true
    vim.api.nvim_set_keymap("i", "<C-f>", "copilot#Accept('<CR>')", { noremap = true, silent = true, expr = true })
  end,
}

