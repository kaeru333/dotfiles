-- skkeleton: nvim 内蔵 SKK 日本語入力
-- Escape でノーマルモードに戻ると自動で半角入力に戻る
-- AZIK (US配列) + yaskkserv2 + 全角句読点

return {
  -- denops: skkeleton の必須依存 (Deno ベース)
  {
    "vim-denops/denops.vim",
    lazy = false,
    init = function()
      local deno = vim.fn.expand("~/.deno/bin/deno")
      if vim.fn.executable(deno) == 1 then
        vim.g["denops#deno"] = deno
      end
    end,
  },

  -- AZIK かなテーブル (US 配列用)
  {
    "k16em/skkeleton-azik-kanatable",
    lazy = false,
    dependencies = { "vim-skk/skkeleton" },
  },

  -- skkeleton 本体
  {
    "vim-skk/skkeleton",
    lazy = false,
    dependencies = { "vim-denops/denops.vim" },
    config = function()
      -- 初期化前フックで辞書・かなテーブルを設定
      vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-initialize-pre",
        callback = function()
          vim.fn["skkeleton#azik#add_table"]("us")
          vim.fn["skkeleton#config"]({
            globalJisyo = "/usr/share/skk/SKK-JISYO.L",
            userJisyo = vim.fn.expand("~/.config/fcitx5/skk/user.dict"),
            skkServerHost = "127.0.0.1",
            skkServerPort = 1178,
            skkServerReqEncoding = "utf-8",
            skkServerResEncoding = "utf-8",
            kanaTable = "azik",
            eggLikeNewline = true,
            pageSize = 7,
          })
          -- 句読点: 全角カンマ・ピリオド
          vim.fn["skkeleton#register_kanatable"]("azik", {
            [","] = { "，", "" },
            ["."] = { "．", "" },
          }, true)
        end,
      })

      -- skkeleton が有効化されたら <Esc>/<C-[> を上書き:
      -- disable してからノーマルモードへ抜ける
      -- (skkeleton は <Esc> を自前でインターセプトするため上書きが必要)
      vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-enable-post",
        callback = function()
          local opts = { buffer = true, nowait = true, noremap = true }
          vim.keymap.set("i", "<Esc>",
            "<Cmd>call skkeleton#disable()<CR><Esc>", opts)
          vim.keymap.set("i", "<C-[>",
            "<Cmd>call skkeleton#disable()<CR><Esc>", opts)
        end,
      })

      -- C-j: かな入力 ON / C-l: かな入力 OFF
      vim.keymap.set({ "i", "c" }, "<C-j>", "<Plug>(skkeleton-enable)")
      vim.keymap.set({ "i", "c" }, "<C-l>", "<Plug>(skkeleton-disable)")

      -- InsertLeave でも念のため disable (fcitx5 経由などのフォールバック)
      vim.api.nvim_create_autocmd("InsertLeave", {
        group = vim.api.nvim_create_augroup("skkeleton_leave", { clear = true }),
        callback = function()
          if vim.fn["skkeleton#is_enabled"]() == 1 then
            vim.fn["skkeleton#disable"]()
          end
        end,
      })
    end,
  },
}
