return {
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    config = function()
      -- Python: pyright
      vim.lsp.config.pyright = {
        cmd = { 'pyright-langserver', '--stdio' },
        filetypes = { 'python' },
        root_dir = vim.fs.root(0, {'.git', 'pyproject.toml', 'setup.py'}),
        single_file_support = true,
      }

      -- LaTeX: texlab
      vim.lsp.config.texlab = {
        cmd = { "texlab" },
        filetypes = { "tex", "bib" },
        root_dir = vim.fs.root(0, {"compile.sh", ".git"}),
        single_file_support = true,
        settings = {
          texlab = {
            build = {
              onSave = true,
              args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "-outdir=%O", "%S" },
            },
            forwardSearch = {
              args = { "-forward-search", "%p", "%l" },
            },
          },
        },
      }

      -- LSP サーバーを有効化
      vim.lsp.enable('pyright')
      vim.lsp.enable('texlab')

      -- LSP キーマップ設定（バッファにアタッチされたときに適用）
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local bufnr = args.buf
          local opts = { buffer = bufnr, noremap = true, silent = true }

          -- === 基本操作（go to 系）===
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)           -- go to definition（定義へ移動）
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)          -- go to Declaration（宣言へ移動）
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)       -- go to implementation（実装へ移動）
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)           -- go to references（参照検索）
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)                 -- Keyword lookup（ホバー情報表示）

          -- === 編集操作 ===
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)       -- rename（変数名変更）
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)  -- code action（コードアクション）

          -- === エラー/診断 ===
          vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts) -- error（エラー詳細表示）
          vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)         -- 前の diagnostic へ移動
          vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)         -- 次の diagnostic へ移動
        end,
      })
    end,
  },
}
