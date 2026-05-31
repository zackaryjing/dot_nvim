return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "super-tab",
      },
      completion = {
        trigger = {
          show_in_snippet = false,
        },
      },
      sources = {
        providers = {
          snippets = {
            opts = {
              clipboard_register = "+",
            },
          },
        },
      },
    },
  },
}
