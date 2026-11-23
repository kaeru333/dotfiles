-- markdown をバッファ内で装飾描画する (見出し・箇条書き・チェックボックス・表など) ．
-- conceallevel はプラグインがウィンドウ単位で切り替える (描画時 3 / 非描画時は
-- core/options.lua の値) ため，グローバル設定はいじらなくてよい．
return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ft = { "markdown", "quarto" },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    file_types = { "markdown", "quarto" },
    -- チェックボックス・callout の補完を本プラグイン内蔵の LSP から供給する
    completions = { lsp = { enabled = true } },
  },
}
