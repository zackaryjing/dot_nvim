return {
  {
    "folke/flash.nvim",
    opts = {
      modes = {
        char = {
          char_actions = function()
            return {
              [";"] = "next",
              [","] = "prev",
            }
          end,
        },
      },
    },
    keys = {
      { "s", false, mode = { "n", "x", "o" } },
      { "S", false, mode = { "n", "x", "o" } },
      { "<leader>j", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    },
  },
}
