-- herdr-nvim: herdr ワークスペース内の agent へコードコメント/参照を送る
-- 前提: herdr セッション内で nvim を起動していること (herdr >= 0.7.5)
-- herdr 外 (HERDR_ENV 未設定) ではロードしない
return {
    "ChmaraX/herdr-nvim",
    cond = vim.env.HERDR_ENV ~= nil,
    event = "VeryLazy",
    opts = {
        -- デフォルトのキーマップは使わず、下で明示的に定義する
        keymaps = false,
    },
    config = function(_, opts)
        local herdr = require("herdr-nvim")
        herdr.setup(opts)

        -- <leader>ac: 現在行 (normal) / 選択範囲 (visual, V-line) に agent 向けコメント
        vim.keymap.set("n", "<leader>ac", herdr.comment_line, { desc = "Herdr: 行にコメント" })
        vim.keymap.set("x", "<leader>ac", herdr.comment_selection, { desc = "Herdr: 選択範囲にコメント" })
        -- <leader>as: 溜めたコメントを agent の入力欄へ転送 (自動送信はしない)
        vim.keymap.set("n", "<leader>as", function()
            herdr.send_all({ submit = false })
        end, { desc = "Herdr: コメントを agent へ転送" })
        vim.keymap.set("n", "<leader>al", herdr.list_comments, { desc = "Herdr: コメント一覧" })
    end,
}
