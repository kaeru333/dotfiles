-- skkeleton: nvim 内蔵 SKK 日本語入力 (Linux / macOS 両対応)
-- Escape でノーマルモードに戻ると自動で半角入力に戻る
-- AZIK (US配列) + 全角句読点
--
-- OS ごとの差異:
--   * deno      : Linux=~/.deno/bin/deno、mac=Homebrew (PATH) を自動検出
--   * 辞書       : Linux=/usr/share/skk、mac=AquaSKK 同梱辞書を流用
--   * SKK サーバ : yaskkserv2 (Linux のみ)。mac は辞書ファイルで完結

-- denops の実行に deno が必須。見つからなければ skkeleton 一式をロードしない
-- (denops がエラーを出すのを防ぎ、両 OS で「OS 固有エラーなし」を担保する)
local function find_deno()
  local home_deno = vim.fn.expand("~/.deno/bin/deno")
  if vim.fn.executable(home_deno) == 1 then
    return home_deno
  end
  if vim.fn.executable("deno") == 1 then
    return vim.fn.exepath("deno")
  end
  return nil
end

local deno = find_deno()

if not deno then
  vim.schedule(function()
    vim.notify(
      "skkeleton: deno が見つからないため日本語入力を無効化しました "
        .. "(導入: macOS=`brew install deno` / Linux=deno を PATH に)",
      vim.log.levels.WARN
    )
  end)
  return {}
end

return {
  -- denops: skkeleton の必須依存 (Deno ベース)
  {
    "vim-denops/denops.vim",
    lazy = false,
    init = function()
      vim.g["denops#deno"] = deno
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

          -- グローバル辞書 (euc-jp): OS ごとの候補から実在するものを採用
          local global_jisyo = "/usr/share/skk/SKK-JISYO.L"
          local candidates = {
            "/usr/share/skk/SKK-JISYO.L", -- Linux (skk-dicts)
            "/opt/homebrew/share/skk/SKK-JISYO.L", -- mac (brew, あれば)
            vim.fn.expand("~/Library/Application Support/AquaSKK/SKK-JISYO.L"), -- mac (AquaSKK)
          }
          for _, p in ipairs(candidates) do
            if vim.fn.filereadable(p) == 1 then
              global_jisyo = p
              break
            end
          end

          -- ユーザー辞書: OS ごとに保存先を分ける (skkeleton が自動生成)
          local user_jisyo
          if vim.fn.has("mac") == 1 then
            user_jisyo = vim.fn.expand("~/.local/share/skkeleton/user.dict")
          else
            user_jisyo = vim.fn.expand("~/.config/fcitx5/skk/user.dict")
          end
          vim.fn.mkdir(vim.fn.fnamemodify(user_jisyo, ":h"), "p")

          -- 現行 skkeleton のスキーマに準拠 (旧 globalJisyo/userJisyo/pageSize は廃止)。
          -- 未知キーを渡すと skkeleton#config が例外を投げ初期化全体が止まるため注意。
          local config = {
            globalDictionaries = { { global_jisyo, "euc-jp" } },
            userDictionary = user_jisyo,
            kanaTable = "azik",
            eggLikeNewline = true,
            -- 既定は辞書ファイルのみ (mac はこれで完結)
            sources = { "skk_dictionary" },
          }

          -- SKK サーバ (yaskkserv2) は Linux のみ。mac は辞書ファイルで完結させる
          if vim.fn.has("mac") == 0 then
            config.skkServerHost = "127.0.0.1"
            config.skkServerPort = 1178
            -- yaskkserv2 は euc-jp で応答するため要求/応答とも euc-jp
            config.skkServerReqEnc = "euc-jp"
            config.skkServerResEnc = "euc-jp"
            -- skkServer を使うには sources に "skk_server" を明示する必要がある
            config.sources = { "skk_server", "skk_dictionary" }
          end

          vim.fn["skkeleton#config"](config)

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
