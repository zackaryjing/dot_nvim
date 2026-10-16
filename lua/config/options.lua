-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

require("config.platform").setup_path()

-- Keep the system clipboard opt-in: only explicit "+ register mappings
-- (<leader>y / <leader>p / <leader>d) touch it. LazyVim defaults to
-- clipboard=unnamedplus, which makes plain y/d/x write there too.
vim.opt.clipboard = ""

vim.opt.virtualedit = "onemore"
vim.opt.listchars = { tab = "> ", nbsp = "+" }
