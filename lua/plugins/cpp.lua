local cpp_terminal

local function run_cpp_file(position)
  local source = vim.api.nvim_buf_get_name(0)
  if vim.bo.filetype ~= "cpp" or source == "" then
    return Snacks.notify.warn("Current buffer is not a saved C++ file")
  end

  vim.cmd.write()

  local root = vim.fs.root(source, { "compile_flags.txt", ".git" }) or vim.fn.getcwd()
  local output_dir = root .. "/output"
  local executable = output_dir .. "/" .. vim.fn.fnamemodify(source, ":t:r")
  local escape = vim.fn.shellescape
  local compile_command = "clang++ -std=c++26 -fsanitize=address -g " .. escape(source) .. " -o " .. escape(executable)
  local command = table.concat({
    "mkdir -p " .. escape(output_dir),
    "printf '\\n[build] %s\\n' " .. escape(compile_command),
    "if " .. compile_command .. "; then",
    "  printf '\\n[run] %s\\n\\n' " .. escape(executable),
    "  cd " .. escape(output_dir) .. " || exit 1",
    "  " .. escape("./" .. vim.fn.fnamemodify(executable, ":t")),
    "  exit_code=$?",
    "  printf '\\n[process exited with code %s]\\n' \"$exit_code\"",
    "else",
    "  exit_code=$?",
    "  printf '\\n[build failed with code %s]\\n' \"$exit_code\"",
    "fi",
    "exec " .. escape(vim.o.shell),
  }, "\n")

  if cpp_terminal and cpp_terminal:buf_valid() then
    cpp_terminal:close()
  end
  local win = position == "bottom" and {
    position = "bottom",
    height = 0.35,
    wo = { winbar = " C++ Run " },
  } or {
    position = "float",
  }

  cpp_terminal = Snacks.terminal.open({ vim.o.shell, "-lc", command }, {
    cwd = root,
    auto_close = false,
    win = win,
  })
end

return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>rr", function() run_cpp_file("float") end, desc = "Compile and Run C++ File (Float)" },
      { "<leader>rc", function() run_cpp_file("bottom") end, desc = "Compile and Run C++ File (Bottom)" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          mason = false,
          cmd = {
            "clangd-20",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = { "clang-format" },
        cpp = { "clang-format" },
      },
    },
  },
}
