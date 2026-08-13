local cpp_terminal
local run_cpp_bottom
local Platform = require("config.platform")

local function cpp_run_context()
  local source = vim.api.nvim_buf_get_name(0)
  if vim.bo.filetype ~= "cpp" or source == "" then
    Snacks.notify.warn("Current buffer is not a saved C++ file")
    return
  end

  vim.cmd.write()

  local root = vim.fs.root(source, { "compile_flags.txt", ".git" }) or vim.fn.getcwd()
  local output_dir = root .. "/output"
  local executable = output_dir .. "/" .. vim.fn.fnamemodify(source, ":t:r")
  local escape = vim.fn.shellescape
  local toolchain = Platform.cpp_toolchain()
  if not toolchain then
    Snacks.notify.error("No compatible C++ compiler was found")
    return
  end

  local compile_command = table.concat({
    escape(toolchain.compiler),
    "-std=" .. toolchain.standard,
    "-fsanitize=address",
    "-g",
    escape(source),
    "-o",
    escape(executable),
  }, " ")
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
  }, "\n")

  return root, command
end

local function run_cpp_external()
  local root, command = cpp_run_context()
  if not root then
    return
  end

  local wait_for_escape = table.concat({
    "printf '\\n[press Esc to close]\\n'",
    "while IFS= read -r -s -n 1 key; do",
    "  [ \"$key\" = $'\\e' ] && break",
    "done",
  }, "\n")

  if not Platform.open_external_terminal(root, command .. "\n" .. wait_for_escape) then
    Snacks.notify.info("No supported external terminal found; using the Neovim terminal")
    run_cpp_bottom()
  end
end

run_cpp_bottom = function()
  local root, command = cpp_run_context()
  if not root then
    return
  end

  if cpp_terminal and cpp_terminal:buf_valid() then
    cpp_terminal:close()
  end
  local win = {
    position = "bottom",
    height = 0.35,
    wo = { winbar = " C++ Run " },
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
      { "<leader>rr", run_cpp_external, desc = "Compile and Run C++ File (External Terminal)" },
      { "<leader>rc", run_cpp_bottom, desc = "Compile and Run C++ File (Bottom)" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local clangd = Platform.clangd()
      opts.servers = opts.servers or {}
      opts.servers.clangd = vim.tbl_deep_extend("force", opts.servers.clangd or {}, {
        mason = false,
        cmd = {
          clangd or "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders",
          "--fallback-style=llvm",
        },
      })
    end,
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
