return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    event = "VeryLazy",
    priority = 1000,
    opts = {
      transparent_background = true,
    },
    init = function()
      vim.cmd.colorscheme("catppuccin")
      vim.api.nvim_set_hl(0, "CursorLine", { bg = "NONE", sp = "#4c6a8c", underline = true})
      vim.api.nvim_set_hl(0, "CursorColumn", { bg = "NONE", underline = true, sp = "#4c6a8c"})
    end,
  },
}
