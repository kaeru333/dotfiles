-- lazygit.nvim: Neovim から lazygit を起動するためのプラグイン
-- 前提: lazygit がシステムにインストールされていること
return {
    "kdheepak/lazygit.nvim",
    cmd = {
        "LazyGit",
        "LazyGitConfig",
        "LazyGitCurrentFile",
        "LazyGitFilter",
        "LazyGitFilterCurrentFile",
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    keys = {
        { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit を開く" },
    },
}
