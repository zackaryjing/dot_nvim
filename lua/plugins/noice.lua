return {
  {
    "folke/noice.nvim",
    opts = {
      lsp = {
        -- Don't auto-open the signature help popup while typing (e.g. "(" or ","
        -- in Python). View it on demand with gK (or <c-k> in insert mode).
        signature = {
          auto_open = {
            enabled = false,
          },
        },
      },
    },
  },
}
