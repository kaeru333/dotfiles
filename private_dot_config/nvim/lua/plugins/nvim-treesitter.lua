return {
    "nvim-treesitter/nvim-treesitter",
    event = "BufReadPost",
    build = ":TSUpdate",
    priority = 1000,
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "elixir", "heex", "javascript", "html", "markdown", "markdown_inline" },
      })
      vim.treesitter.language.register("markdown", "mdx")
    end,
}
