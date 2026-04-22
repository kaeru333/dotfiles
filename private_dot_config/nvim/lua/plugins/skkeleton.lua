-- skkeleton: nvim 内蔵 SKK 日本語入力
-- Escape でノーマルモードに戻ると自動で半角入力に戻る
-- AZIK (US配列) + yaskkserv2 + 全角句読点

return {
  -- denops: skkeleton の必須依存 (Deno ベース)
  {
    "vim-denops/denops.vim",
    lazy = false,
    init = function()
      -- Deno のパスを明示指定
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
      -- 初期化前フックで設定を注入
      vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-initialize-pre",
        callback = function()
          -- AZIK (US配列) テーブルを追加
          vim.fn["skkeleton#azik#add_table"]("us")

          vim.fn["skkeleton#config"]({
            -- 辞書設定
            globalJisyo = "/usr/share/skk/SKK-JISYO.L",
            userJisyo = vim.fn.expand("~/.config/fcitx5/skk/user.dict"),
            -- yaskkserv2 (jinmei + propernoun + station + geo 等を統合)
            skkServerHost = "127.0.0.1",
            skkServerPort = 1178,
            skkServerReqEncoding = "utf-8",
            skkServerResEncoding = "utf-8",
            -- AZIK かなテーブルを有効化
            kanaTable = "azik",
            -- egg-like 改行: Enter = 確定のみ、改行しない
            eggLikeNewline = true,
            -- 変換候補数
            pageSize = 7,
          })

          -- 句読点を全角カンマ・ピリオドに変更 (fcitx5-skk の設定に合わせる)
          vim.fn["skkeleton#register_kanatable"]("azik", {
            [","] = { "，", "" },
            ["."] = { "．", "" },
          }, true)
        end,
      })

      -- C-j: かな入力 ON、C-l: かな入力 OFF
      vim.keymap.set({ "i", "c" }, "<C-j>", "<Plug>(skkeleton-enable)")
      vim.keymap.set({ "i", "c" }, "<C-l>", "<Plug>(skkeleton-disable)")

      -- InsertLeave で自動的に無効化 → 半角入力に戻る
      vim.api.nvim_create_autocmd("InsertLeave", {
        group = vim.api.nvim_create_augroup("skkeleton_leave", { clear = true }),
        callback = function()
          vim.fn["skkeleton#disable"]()
        end,
      })
    end,
  },
}
