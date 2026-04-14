local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

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
