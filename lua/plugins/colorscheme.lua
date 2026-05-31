return {
  {
    "folke/tokyonight.nvim",
    opts = {
      on_colors = function(colors)
        if vim.o.background == "light" then
          colors.bg = "#ffffff"
        end
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-day",
    },
  },
}
