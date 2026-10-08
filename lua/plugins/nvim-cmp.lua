return {
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")

      opts.experimental = opts.experimental or {}
      opts.experimental.ghost_text = false

      opts.window = opts.window or {}
      opts.window.completion = opts.window.completion or {}
      opts.window.completion.winblend = 0
      opts.window.documentation = opts.window.documentation or {}
      opts.window.documentation.winblend = 0

      for _, source in ipairs(opts.sources or {}) do
        if source.name == "snippets" then
          local previous_filter = source.entry_filter
          source.entry_filter = function(entry, context)
            if previous_filter and not previous_filter(entry, context) then
              return false
            end

            local before_cursor = context and context.cursor_before_line
            if not before_cursor then
              local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
              before_cursor = vim.api.nvim_get_current_line():sub(1, cursor_col)
            end
            local is_member_access = before_cursor:match("%.[%w_]*$")
              or before_cursor:match("%-%>[%w_]*$")
              or before_cursor:match("::[%w_]*$")
              or (vim.bo.filetype == "lua" and before_cursor:match(":[%w_]*$"))

            return not is_member_access
          end
        end
      end

      -- Don't highlight any completion item by default. With the default
      -- (completeopt without "noselect") cmp marks the first entry as selected,
      -- so <CR> would silently accept it -- e.g. typing "0.1" right after
      -- "0.6128" replaces it with "0.6128" instead of inserting a newline.
      opts.completion = opts.completion or {}
      opts.completion.completeopt = "menu,menuone,noinsert,noselect"
      opts.preselect = cmp.PreselectMode.None
      -- <CR> confirms only an explicitly selected item, otherwise falls back to
      -- a newline. <Tab> below still accepts the top item in one keystroke.
      opts.mapping["<CR>"] = LazyVim.cmp.confirm({ select = false })

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
