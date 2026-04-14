-- 1. よく使うオプションを定義しておくと便利です
local default_opts = { noremap = true, silent = true }

-- 2. 設定リスト： { mode, key, command, options } の順で並べる
local keymaps = {
    -- [1]mode, [2]key,       [3]command,                         [4]options
    { "n",     "<leader>t",  ":neotree toggle<cr>",              default_opts },
    { "n",     "<leader>f",  "<cmd>telescope find_files<cr>",    default_opts },
    { "n",     "<leader>s",  "<cmd>telescope live_grep<cr>",     default_opts },
}

-- 3. ipairsを使ってリストを順番に処理
-- entry には { "n", "<leader>t", ... } という配列が入ってくる
for _, entry in ipairs(keymaps) do
    local mode = entry[1]
    local key  = entry[2]
    local cmd  = entry[3]
    local opts = entry[4]

    vim.api.nvim_set_keymap(mode, key, cmd, opts)
end
