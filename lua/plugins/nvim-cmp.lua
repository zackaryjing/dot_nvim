return {
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")

      opts.mapping["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.confirm({ select = true })
        elseif LazyVim.cmp.map({ "snippet_forward", "ai_nes", "ai_accept" })() then
          return
        else
          fallback()
        end
      end, { "i", "s" })

      opts.mapping["<S-Tab>"] = cmp.mapping(function(fallback)
        if vim.snippet.active({ direction = -1 }) then
          vim.snippet.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" })
    end,
  },
  {
    "garymjr/nvim-snippets",
    opts = function()
      require("snippets.utils.builtin").lazy.CLIPBOARD = function()
        return vim.fn.getreg("+", true)
      end
    end,
  },
}
