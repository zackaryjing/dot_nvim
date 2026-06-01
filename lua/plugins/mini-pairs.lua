local function map_cpp_angle_pairs(buf)
  local pairs = require("mini.pairs")

  pairs.map_buf(buf, "i", "<", {
    action = "open",
    pair = "<>",
    neigh_pattern = "[%w_>:][^=]",
    register = { cr = false },
  })
  pairs.map_buf(buf, "i", ">", {
    action = "close",
    pair = "<>",
    register = { cr = false },
  })
end

return {
  {
    "nvim-mini/mini.pairs",
    opts = function(_, opts)
      if not opts.skip_next:find("%(", 1, true) then
        opts.skip_next = opts.skip_next:gsub("%]$", "%%(%]")
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("personal_cpp_angle_pairs", { clear = true }),
        pattern = "cpp",
        callback = function(args)
          map_cpp_angle_pairs(args.buf)
        end,
      })

      vim.schedule(function()
        if vim.bo.filetype == "cpp" then
          map_cpp_angle_pairs(0)
        end
      end)
    end,
    config = function(_, opts)
      LazyVim.mini.pairs(opts)

      if not MiniPairs._personal_preserve_indent then
        local cr = MiniPairs.cr
        MiniPairs.cr = function(key)
          return cr(key) .. " " .. vim.api.nvim_replace_termcodes("<BS>", true, false, true)
        end
        MiniPairs._personal_preserve_indent = true
      end
    end,
  },
}
