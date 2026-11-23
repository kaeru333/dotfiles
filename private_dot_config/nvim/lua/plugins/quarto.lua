return {
  "quarto-dev/quarto-nvim",
  dependencies = {
    "jmbuhr/otter.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  -- lazy.nvim の遅延ロードキーは `ft`．`filetype` は無効キーで無視され，
  -- 結果として起動時に常時ロードされてしまうため修正
  ft = { "quarto", "qmd" },
  opts = {
    debug = false,
    closePreviewOnExit = true,
    lspFeatures = {
      enabled = true,
      chunks = "curly",
      languages = { "r", "python", "julia", "bash", "html" },
      diagnostics = {
        enabled = true,
        triggers = { "BufWritePost" },
      },
      completion = {
        enabled = true,
      },
    },
    codeRunner = {
      enabled = true,
      default_method = "slime",
      ft_runners = {},
      never_run = { 'yaml' },
    },
    markdown = {
      codechunk = {
        highlight = true,
      },
    },
  }, 
}
