local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- fcitx5 を nvim では常時無効化: skkeleton が日本語入力を担当するため
-- リスト形式でシェルを介さずに直接実行 (shellcmdflag="-ic" による遅延を回避)
if vim.fn.executable("fcitx5-remote") == 1 then
  local function deactivate_fcitx5()
    vim.fn.system({ "fcitx5-remote", "-c" })
  end

  autocmd({ "VimEnter", "InsertEnter", "InsertLeave", "CmdlineLeave" }, {
    group = augroup("fcitx5", { clear = true }),
    callback = deactivate_fcitx5,
  })

  -- グローバル Esc マッピング: skkeleton 未使用時 (fcitx5-skk 直接使用) にも
  -- 確実に deactivate してからノーマルモードへ戻る
  -- (skkeleton が有効なときは buffer-local 側が優先される)
  vim.keymap.set("i", "<Esc>", function()
    deactivate_fcitx5()
    return "<Esc>"
  end, { expr = true, noremap = true })
end

-- 未インストールプラグインの自動インストールは lazy.nvim のデフォルト機能
-- (install.missing = true) に任せる

-- 起動時に lazy.nvim で check (fetch のみ) を実行し、
-- 実際に更新があるプラグインが存在する場合のみ update を実行する
autocmd("VimEnter", {
  group = augroup("autoupdate", { clear = true }),
  callback = function()
    vim.schedule(function()
      local ok_lazy, lazy = pcall(require, "lazy")
      if not ok_lazy then
        return
      end

      local ok_check, runner = pcall(lazy.check, { show = false })
      if not ok_check or not runner then
        return
      end

      runner:wait(function()
        local ok_status, status = pcall(require, "lazy.status")
        if not ok_status then
          return
        end
        if status.has_updates() then
          pcall(lazy.update, { show = false })
        end
      end)
    end)
  end,
})

autocmd({"FocusGained", "BufEnter", "CursorHold", "CursorHoldI"}, {
  group = augroup("checktime", { clear = true }),
  command = "checktime",
})

local augroup = vim.api.nvim_create_augroup('FileTypeSettings', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = { "markdown" },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
    vim.bo.expandtab = true
  end,
})
