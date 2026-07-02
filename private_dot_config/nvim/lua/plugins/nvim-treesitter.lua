return {
    "nvim-treesitter/nvim-treesitter",
    event = "BufReadPost",
    build = ":TSUpdate",
    priority = 1000,
    config = function()
      -- master ブランチでは nvim-treesitter.configs.setup を使う
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "python", "elixir", "heex", "javascript", "html", "markdown", "markdown_inline" },
        -- treesitter ハイライトを有効化（f-string の {} 内も色付けされる）
        highlight = { enable = true },
        indent = { enable = true },
      })
      vim.treesitter.language.register("markdown", "mdx")
    end,
}
