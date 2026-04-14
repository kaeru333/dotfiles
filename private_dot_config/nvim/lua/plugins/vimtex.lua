return {
  "lervag/vimtex",
  event = "VeryLazy",
  ft = { "tex", "latex" },
  -- tag = "v2.15", -- uncomment to pin to a specific release
  init = function()
    if vim.fn.has("mac") == 1 then
      vim.g.vimtex_view_method = "skim"
    else
      vim.g.vimtex_view_method = "zathura"
    end
  end,
  keys = {
    {
      "<leader>lb",
      function()
        vim.cmd("write")
        vim.cmd("VimtexCompileSS")
      end,
      ft = "tex",
      desc = "LaTeX: 保存して単発コンパイル",
    },
  },
}
