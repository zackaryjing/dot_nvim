local M = {}

local uv = vim.uv
local uname = uv.os_uname()

M.is_windows = vim.fn.has("win32") == 1
M.is_macos = vim.fn.has("mac") == 1
M.is_wsl = not M.is_windows
  and (vim.env.WSL_DISTRO_NAME ~= nil or uname.release:lower():find("microsoft", 1, true) ~= nil)
M.has_wsl_interop = M.is_wsl
  and (vim.env.WSL_INTEROP ~= nil or uv.fs_stat("/proc/sys/fs/binfmt_misc/WSLInterop") ~= nil)
M.path_separator = M.is_windows and ";" or ":"

local function add_to_path(path, prepend)
  if not path or not uv.fs_stat(path) then
    return
  end

  local paths = vim.split(vim.env.PATH or "", M.path_separator, { plain = true })
  if vim.tbl_contains(paths, path) then
    return
  end

  if prepend then
    table.insert(paths, 1, path)
  else
    table.insert(paths, path)
  end
  vim.env.PATH = table.concat(paths, M.path_separator)
end

function M.setup_path()
  add_to_path(vim.fn.expand("~/.local/bin"), true)

  -- WSL normally strips Windows paths from PATH in this setup. Adding only the
  -- Windows directory lets vim.ui.open() find explorer.exe without importing
  -- the much larger Windows user PATH.
  if M.has_wsl_interop then
    add_to_path("/mnt/c/Windows", false)
  end
end

---@param candidates string[]
---@return string?
function M.executable(candidates)
  for _, candidate in ipairs(candidates) do
    local path = vim.fn.exepath(candidate)
    if path ~= "" then
      return path
    end
  end
end

local cpp_toolchain

---@return { compiler: string, standard: string }?
function M.cpp_toolchain()
  if cpp_toolchain then
    return cpp_toolchain
  end

  local compiler = M.executable({
    "clang++-20",
    "clang++-19",
    "clang++-18",
    "clang++-17",
    "clang++",
    "g++-15",
    "g++-14",
    "g++-13",
    "g++-12",
    "g++",
    "c++",
  })
  if not compiler then
    return
  end

  for _, standard in ipairs({ "c++26", "c++2c", "c++23", "c++2b", "c++20" }) do
    local result = vim
      .system({ compiler, "-std=" .. standard, "-x", "c++", "-fsyntax-only", "-" }, { stdin = "int main() {}\n", text = true })
      :wait()
    if result.code == 0 then
      cpp_toolchain = { compiler = compiler, standard = standard }
      return cpp_toolchain
    end
  end
end

function M.clangd()
  return M.executable({
    "clangd-20",
    "clangd-19",
    "clangd-18",
    "clangd-17",
    "clangd-16",
    "clangd-15",
    "clangd-14",
    "clangd",
  })
end

local function windows_terminal()
  if not M.has_wsl_interop then
    return
  end

  local matches = vim.fn.glob("/mnt/c/Users/*/AppData/Local/Microsoft/WindowsApps/wt.exe", false, true)
  return matches[1]
end

---@param root string
---@param command string
---@return boolean
function M.open_external_terminal(root, command)
  local shell = M.executable({ "bash", "zsh", "sh" }) or vim.o.shell
  local terminal = M.executable({ "gnome-terminal" })
  if terminal then
    vim.system({
      terminal,
      "--title=C++ Run",
      "--working-directory=" .. root,
      "--",
      shell,
      "-lc",
      command,
    }, { detach = true })
    return true
  end

  terminal = M.executable({ "wezterm" })
  if terminal then
    vim.system({ terminal, "start", "--cwd", root, "--", shell, "-lc", command }, { detach = true })
    return true
  end

  terminal = M.executable({ "kitty" })
  if terminal then
    vim.system({ terminal, "--directory", root, shell, "-lc", command }, { detach = true })
    return true
  end

  terminal = M.executable({ "alacritty" })
  if terminal then
    vim.system({ terminal, "--working-directory", root, "-e", shell, "-lc", command }, { detach = true })
    return true
  end

  local wt = windows_terminal()
  local wsl = "/mnt/c/Windows/System32/wsl.exe"
  if wt and uv.fs_stat(wsl) then
    vim.system({
      wt,
      "new-tab",
      "--title",
      "C++ Run",
      wsl,
      "-d",
      vim.env.WSL_DISTRO_NAME or "",
      "--cd",
      root,
      shell,
      "-lc",
      command,
    }, { detach = true })
    return true
  end

  return false
end

return M
