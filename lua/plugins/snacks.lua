return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        win = {
          height = 10,
          keys = {
            hide_slash = false,
            hide_underscore = false,
          },
        },
      },
      picker = {
        sources = {
          explorer = {
            layout = {
              layout = {
                width = 30,
                min_width = 30,
              },
            },
          },
        },
      },
    },
  },
}
