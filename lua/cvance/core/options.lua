vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt

opt.background = "dark"
opt.number = true
opt.relativenumber = true
opt.syntax = "enable"
opt.cursorline = true
opt.mouse = "a"
opt.encoding = "utf-8"
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.splitright = true
opt.splitbelow = true
opt.laststatus = 2
opt.cursorline = true
opt.showmatch = true
opt.showcmd = true
opt.ruler = true
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.cursorline = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.clipboard:append("unnamedplus")
