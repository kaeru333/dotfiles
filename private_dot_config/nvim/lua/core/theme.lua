-- 配色モード (light / dark) の管理．
--
-- 状態は端末側と共有するため ~/.local/state/theme-mode に置く．
-- 書き換えは theme-toggle が行い，起動中の nvim には
--   nvim --server <sock> --remote-expr "luaeval(\"require('core.theme').apply('light')\")"
-- で反映される．手動で切り替える場合は :ThemeApply light|dark を使う．

local M = {}

--- 状態ファイルのパス．
---@return string
local function state_path()
  local dir = vim.env.XDG_STATE_HOME
  if not dir or dir == "" then
    dir = vim.env.HOME .. "/.local/state"
  end
  return dir .. "/theme-mode"
end

--- 状態ファイルから現在の配色モードを読む．読めなければ dark 扱いにする．
---@return string light または dark
function M.current()
  local ok, lines = pcall(vim.fn.readfile, state_path())
  if ok and lines and lines[1] and vim.trim(lines[1]) == "light" then
    return "light"
  end
  return "dark"
end

--- treesitter の細かい色分けを抑え, 以前の Vim 標準シンタックスに近い見た目にする．
---@param colors table catppuccin のパレット
---@return table ハイライト定義
local function custom_highlights(colors)
  return {
    -- 変数系はすべてテキスト色に統一（オレンジ/白が混在しないように）
    ["@variable"] = { fg = colors.text },
    ["@variable.parameter"] = { fg = colors.text },
    ["@variable.member"] = { fg = colors.text },
    ["@property"] = { fg = colors.text },
    ["@field"] = { fg = colors.text },
    -- self/cls などの組み込み変数のみ控えめに着色
    ["@variable.builtin"] = { fg = colors.red },
    -- 関数は宣言・呼び出し・メソッドをすべて同色に統一
    ["@function"] = { fg = colors.blue },
    ["@function.call"] = { fg = colors.blue },
    ["@function.method"] = { fg = colors.blue },
    ["@function.method.call"] = { fg = colors.blue },
    ["@constructor"] = { fg = colors.blue },
  }
end

--- 配色モードを適用する．
--- ダークは従来どおり catppuccin-mocha + 透過，ライトは catppuccin-latte + 透過なし．
---@param mode string|nil light または dark (省略時は状態ファイルに従う)
function M.apply(mode)
  if mode ~= "light" then
    mode = mode == "dark" and "dark" or M.current()
  end
  local light = mode == "light"
  local flavour = light and "latte" or "mocha"

  vim.o.background = mode
  require("catppuccin").setup({
    flavour = flavour,
    transparent_background = not light,
    custom_highlights = custom_highlights,
  })
  vim.cmd.colorscheme("catppuccin-" .. flavour)

  -- カーソル行・列は背景を塗らず下線のみで示す
  local underline = light and "#7287fd" or "#4c6a8c"
  vim.api.nvim_set_hl(0, "CursorLine", { bg = "NONE", sp = underline, underline = true })
  vim.api.nvim_set_hl(0, "CursorColumn", { bg = "NONE", sp = underline, underline = true })

  return mode
end

--- :ThemeApply コマンドを登録し，起動時の配色を適用する．
function M.setup()
  vim.api.nvim_create_user_command("ThemeApply", function(opts)
    M.apply(opts.args ~= "" and opts.args or nil)
  end, {
    nargs = "?",
    complete = function()
      return { "light", "dark" }
    end,
    desc = "配色モードを切り替える (引数なしで状態ファイルに従う)",
  })

  M.apply()
end

return M
