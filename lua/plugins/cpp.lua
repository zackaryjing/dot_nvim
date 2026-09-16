local cpp_terminal
local run_cpp_bottom
local Platform = require("config.platform")

local function ps_quote(value)
  return "'" .. tostring(value):gsub("'", "''") .. "'"
end

local function windows_path(path)
  return path:gsub("/", "\\")
end

local function unix_shellescape(value)
  return vim.fn.shellescape(value)
end

local function cpp_compile_command(toolchain, source, executable, windows)
  local q = windows and ps_quote or unix_shellescape
  local compiler = q(toolchain.compiler)
  if windows then
    compiler = "& " .. compiler
  end
  return table.concat({
    compiler,
    "-std=" .. toolchain.standard,
    "-fsanitize=address",
    "-g",
    q(source),
    "-o",
    q(executable),
  }, " ")
end

local function cpp_run_context()
  local source = vim.api.nvim_buf_get_name(0)
  if vim.bo.filetype ~= "cpp" or source == "" then
    Snacks.notify.warn("Current buffer is not a saved C++ file")
    return
  end

  vim.cmd.write()

  local root = vim.fs.root(source, { "compile_flags.txt", ".git" }) or vim.fn.getcwd()
  local toolchain = Platform.cpp_toolchain()
  if not toolchain then
    Snacks.notify.error("No compatible C++ compiler was found")
    return
  end

  if Platform.is_windows then
    local output_dir = windows_path(root .. "/output")
    local source_path = windows_path(source)
    local executable = output_dir .. "\\" .. vim.fn.fnamemodify(source, ":t:r") .. ".exe"
    local compile_command = cpp_compile_command(toolchain, source_path, executable, true)
    local command = table.concat({
      string.format("New-Item -ItemType Directory -Force -Path %s | Out-Null", ps_quote(output_dir)),
      "Write-Host ''",
      string.format("Write-Host %s", ps_quote("[build] " .. compile_command)),
      compile_command,
      "if ($LASTEXITCODE -ne 0) { Write-Host ''; Write-Host \"[build failed with code $LASTEXITCODE]\"; exit $LASTEXITCODE }",
      "Write-Host ''",
      string.format("Write-Host %s", ps_quote("[run] " .. executable)),
      "Write-Host ''",
      string.format("Set-Location -LiteralPath %s", ps_quote(output_dir)),
      string.format("& %s", ps_quote(executable)),
      "Write-Host ''",
      "Write-Host \"[process exited with code $LASTEXITCODE]\"",
    }, "; ")
    return root, command
  end

  local output_dir = root .. "/output"
  local executable = output_dir .. "/" .. vim.fn.fnamemodify(source, ":t:r")
  local escape = unix_shellescape
  local compile_command = cpp_compile_command(toolchain, source, executable, false)
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

local function cpp_bottom_argv(command)
  if Platform.is_windows then
    local ps = Platform.powershell()
    if not ps then
      Snacks.notify.error("PowerShell is required to run C++ files on Windows")
      return
    end
    return { ps, "-NoLogo", "-NoExit", "-Command", command }
  end
  return { vim.o.shell, "-lc", command }
end

local function run_cpp_external()
  local root, command = cpp_run_context()
  if not root then
    return
  end

  local wait_for_escape
  if Platform.is_windows then
    wait_for_escape = table.concat({
      "Write-Host ''",
      "Write-Host '[press Enter to close]'",
      "Read-Host | Out-Null",
    }, "; ")
  else
    wait_for_escape = table.concat({
      "printf '\\n[press Esc to close]\\n'",
      "while IFS= read -r -s -n 1 key; do",
      "  [ \"$key\" = $'\\e' ] && break",
      "done",
    }, "\n")
  end

  if not Platform.open_external_terminal(root, command .. (Platform.is_windows and "; " or "\n") .. wait_for_escape) then
    Snacks.notify.info("No supported external terminal found; using the Neovim terminal")
    run_cpp_bottom()
  end
end

run_cpp_bottom = function()
  local root, command = cpp_run_context()
  if not root then
    return
  end

  local argv = cpp_bottom_argv(command)
  if not argv then
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

  cpp_terminal = Snacks.terminal.open(argv, {
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
