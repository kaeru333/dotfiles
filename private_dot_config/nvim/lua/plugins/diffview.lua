-- diffview.nvim: Git の差分とファイル履歴を単一のタブページで閲覧するプラグイン
-- 前提: git がシステムにインストールされていること
return {
    "sindrets/diffview.nvim",
    cmd = {
        "DiffviewOpen",
        "DiffviewClose",
        "DiffviewToggleFiles",
        "DiffviewFocusFiles",
        "DiffviewRefresh",
        "DiffviewFileHistory",
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- 必須ではないが推奨
    },
    keys = {
        { "<leader>gd", "<cmd>DiffviewOpen<cr>",          desc = "Diffview: 作業ツリーの差分を開く" },
        { "<leader>gq", "<cmd>DiffviewClose<cr>",         desc = "Diffview: 閉じる" },
        { "<leader>gD", "<cmd>DiffviewClose<cr>",         desc = "Diffview: 閉じる" },
        { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: 現在のファイルの履歴" },
        { "<leader>gH", "<cmd>DiffviewFileHistory<cr>",   desc = "Diffview: リポジトリ全体の履歴" },
        { "<leader>gh", ":DiffviewFileHistory<cr>",       mode = "x", desc = "Diffview: 選択範囲の履歴" },
        { "<leader>gf", "<cmd>DiffviewToggleFiles<cr>",   desc = "Diffview: ファイルパネルのトグル" },
    },
    opts = {
        enhanced_diff_hl = true, -- 差分のハイライトを見やすくする
        view = {
            merge_tool = {
                layout = "diff3_mixed",     -- コンフリクト解決時は 3-way 表示
                disable_diagnostics = true, -- 解決中は LSP 診断を抑止する
            },
        },
        file_panel = {
            listing_style = "tree",
            win_config = { position = "left", width = 35 },
        },
    },
}
