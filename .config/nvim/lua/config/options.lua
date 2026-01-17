-- Basic Neovim options
local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- Search settings
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true

-- Clipboard
opt.clipboard = "unnamedplus"

-- Backspace behavior
opt.backspace = "indent,eol,start"

-- Split windows
opt.splitright = true
opt.splitbelow = true

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Java environment for JDTLS (managed by mise)
-- Use JAVA_HOME from environment if available
if vim.env.JAVA_HOME == nil or vim.env.JAVA_HOME == "" then
  vim.env.JAVA_HOME = vim.fn.system("mise where java"):gsub("\n", "")
end

-- Enable transparent background to match Wezterm's 85% opacity
vim.opt.termguicolors = true
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
vim.api.nvim_set_hl(0, "Folded", { bg = "none" })
vim.api.nvim_set_hl(0, "NonText", { bg = "none" })
vim.api.nvim_set_hl(0, "SpecialKey", { bg = "none" })
vim.api.nvim_set_hl(0, "VertSplit", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
