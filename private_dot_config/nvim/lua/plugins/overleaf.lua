return {
  "kaeru333/overleaf.nvim",
  cmd = { "Overleaf" },
  keys = {
    { "<leader>oc", "<cmd>Overleaf<cr>", desc = "Overleaf: 接続/ステータス" },
    { "<leader>ob", "<cmd>Overleaf compile<cr>", desc = "Overleaf: コンパイル" },
    { "<leader>ot", "<cmd>Overleaf tree<cr>", desc = "Overleaf: ファイルツリー" },
    { "<leader>of", "<cmd>Overleaf search<cr>", desc = "Overleaf: プロジェクト検索" },
    { "<leader>os", "<cmd>Overleaf sync<cr>", desc = "Overleaf: ローカル同期" },
  },
  build = "cd node && npm install",
  config = function()
    require("overleaf").setup({
      env_file = vim.fn.expand("~/.config/nvim/.env"),
      node_path = "/usr/bin/node",
      log_level = "info",
      sync_dir = "~/.overleaf",
      keys = false,
      -- :w のたびにビューアが再起動するのを避ける。PDF はダウンロードされるので
      -- zathura など watch 対応ビューアで一度開けば自動リロードされる。
      auto_open_pdf = false,
    })
    -- :w 時の自動コンパイルは overleaf.nvim 本体の BufWriteCmd (buffer.lua) が担当する
  end,
}
