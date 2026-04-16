vim.scriptencoding = "utf-8"
vim.wo.number = true

local options = {
	encoding = "utf-8",
	fileencoding = "utf-8",
	title = true,
	backup = false,
	clipboard = "unnamedplus",
	cmdheight = 2,
	completeopt = { "menuone", "noselect" },
	conceallevel = 1,
	hlsearch = true,
	ignorecase = true,
	mouse = "a",
	pumheight = 10,
	showmode = false,
	showtabline = 2,
	smartcase = true,
	smartindent = true,
	swapfile = false,
	termguicolors = true,
	timeoutlen = 300,
	undofile = true,
	updatetime = 300,
	writebackup = false,
	shell = "fish",
	backupskip = { "/tmp/*", "/private/tmp/*" },
	expandtab = true,
	shiftwidth = 2,
	tabstop = 2,
	cursorline = false,
	number = true,
	relativenumber = false,
	numberwidth = 4,
	signcolumn = "yes",
	wrap = true,
  breakindent = true,
	winblend = 0,
	wildoptions = "pum",
	pumblend = 0,
	background = "dark",
	scrolloff = 8,
	sidescrolloff = 8,
	guifont = "monospace:h17",
	splitbelow = false, -- オンのとき、ウィンドウを横分割すると新しいウィンドウはカレントウィンドウの下に開かれる
	splitright = false, -- オンのとき、ウィンドウを縦分割すると新しいウィンドウはカレントウィンドウの右に開かれる
}

-- vim.opt.shortmess:append("c")

for k, v in pairs(options) do
	vim.opt[k] = v
end

-- Neovimが使うシェルをfishに設定
vim.o.shell = "fish"

-- シェルを対話的モード(-i)で起動し、コマンド(-c)を実行するよう設定
vim.o.shellcmdflag = "-ic"

vim.o.autoread = true -- ファイルが外部で変更された場合に自動的に再読み込み

-- leaderキーの設定
vim.g.maplocalleader = " "

vim.cmd("set whichwrap+=<,>,[,],h,l")
vim.cmd([[set iskeyword+=-]])
vim.cmd([[set formatoptions-=cro]]) -- TODO: this doesn't seem to work

-- Wayland環境ではwl-copy/wl-pasteを使用
if vim.fn.has("linux") == 1 and vim.fn.executable("wl-copy") == 1 then
	vim.g.clipboard = {
		name = "WL-Clipboard",
		copy = {
			["+"] = "wl-copy",
			["*"] = "wl-copy",
		},
		paste = {
			["+"] = "wl-paste --no-newline",
			["*"] = "wl-paste --no-newline",
		},
		cache_enabled = true,
	}
end

-- vim.api.nvim_set_hl(0, "CursorLine", { bg = "NONE", sp = "#4c6a8c", underline = true})
