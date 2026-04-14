-- return {
--   'nvim-lualine/lualine.nvim',
--   dependencies = { 'nvim-tree/nvim-web-devicons' }, 
--   opts = {
--     options = {
--       theme = "catppuccin", 
--       globalstatus = true, 
--       section_separators = {"", ""}, 
--       component_separators = {"", ""},
--     }, 
--     sections = {
--       lualine_c = {
--         { "filename" }, 
--       }, 
--     }, 
--     extensions = {"fugitive"}, 
--   }
-- }
return {
  'nvim-lualine/lualine.nvim',
  -- 他のプラグイン読み込み後に遅延ロード
  event = "VeryLazy",
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    options = {
      theme = "catppuccin",  -- catppuccinテーマを使用
      globalstatus = true,   -- グローバルステータスを有効に
      section_separators = {"", ""}, 
      component_separators = {"", ""},
    }, 
    sections = {
      lualine_a = {'mode'},  -- モード（挿入モード、コマンドモードなど）
      lualine_b = {'branch', 'diff'},  -- ブランチ名とdiff情報
      lualine_c = {'filename'},  -- ファイル名
      lualine_x = {'encoding', 'fileformat', 'filetype'},  -- エンコーディング、ファイルフォーマット、ファイルタイプ
      lualine_y = {'progress'},  -- 進捗状況
      lualine_z = {'location'},  -- 現在位置（行番号、列番号）
    },
    extensions = {'fugitive'},  -- fugitive拡張を使う場合
  }
}
