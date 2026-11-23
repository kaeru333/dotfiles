-- nvim-treesitter は main ブランチを使う．
-- master ブランチは Neovim 0.11 までのサポートで打ち止めになっており，0.12 では
-- クエリディレクティブ `set-lang-from-info-string!` が
-- 「match[capture_id] が TSNode の配列になる」という 0.11+ の仕様変更に追従できず，
-- フェンス付きコードブロックを含む markdown のパースが例外で停止する
-- (結果としてハイライトも conceal もまとめて効かなくなる) ．
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  -- main ブランチは遅延ロード非対応 (公式 README の IMPORTANT)
  lazy = false,
  priority = 1000,
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")
    ts.setup()

    -- Neovim 0.12 は c / lua / markdown / markdown_inline / query / vim / vimdoc の
    -- パーサとクエリを同梱している．それ以外はここで導入する．
    local ensure = {
      "python",
      "elixir",
      "heex",
      "javascript",
      "html",
      "sql",
    }

    -- main ブランチのパーサビルドは tree-sitter CLI (>= 0.26.1) が必須．
    --   Arch : sudo pacman -S tree-sitter-cli
    --   macOS: brew install tree-sitter-cli
    -- 未導入の環境では同梱パーサのみで動作させる (markdown は同梱ぶんで足りる) ．
    if vim.fn.executable("tree-sitter") == 1 then
      ts.install(ensure)
    else
      vim.schedule(function()
        vim.notify(
          "tree-sitter CLI が無いためパーサ導入をスキップしました．\n"
            .. "Arch: sudo pacman -S tree-sitter-cli / macOS: brew install tree-sitter-cli",
          vim.log.levels.WARN
        )
      end)
    end

    vim.treesitter.language.register("markdown", "mdx")

    -- main ブランチはハイライト/インデントを自動で有効化しない
    -- (どちらも Neovim 本体側の機能) ため，FileType で明示的に開始する．
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
      callback = function(ev)
        -- パーサが無い filetype では start が失敗するので握りつぶす
        if not pcall(vim.treesitter.start, ev.buf) then
          return
        end
        vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
