-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function apply_clang_format_indent()
  local source = vim.api.nvim_buf_get_name(0)
  if source == "" or vim.fn.executable("clang-format") ~= 1 then
    return
  end

  local config = vim.fs.find({ ".clang-format", "_clang-format" }, {
    path = vim.fs.dirname(source),
    upward = true,
  })[1]
  if not config then
    return
  end

  local result = vim.system({
    "clang-format",
    "--style=file",
    "--assume-filename=" .. source,
    "--dump-config",
  }, { text = true }):wait()
  if result.code ~= 0 then
    return
  end

  local indent_width = tonumber(result.stdout:match("\nIndentWidth:%s*(%d+)"))
  local tab_width = tonumber(result.stdout:match("\nTabWidth:%s*(%d+)"))
  local use_tab = result.stdout:match("\nUseTab:%s*(%S+)")

  if indent_width then
    vim.opt_local.shiftwidth = indent_width
    vim.opt_local.softtabstop = indent_width
  end
  if tab_width then
    vim.opt_local.tabstop = tab_width
  end
  if use_tab then
    vim.opt_local.expandtab = use_tab == "Never"
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = apply_clang_format_indent,
})

local function autosave()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].buftype == ""
      and vim.bo[buf].modifiable
      and not vim.bo[buf].readonly
      and vim.bo[buf].modified
      and vim.api.nvim_buf_get_name(buf) ~= ""
    then
      vim.api.nvim_buf_call(buf, function()
        pcall(vim.cmd, "silent noautocmd update")
      end)
    end
  end
end

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  callback = autosave,
})

if _G.personal_autosave_timer then
  _G.personal_autosave_timer:stop()
  _G.personal_autosave_timer:close()
end
_G.personal_autosave_timer = vim.uv.new_timer()
_G.personal_autosave_timer:start(5000, 5000, vim.schedule_wrap(autosave))

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    if _G.personal_autosave_timer then
      _G.personal_autosave_timer:stop()
      _G.personal_autosave_timer:close()
      _G.personal_autosave_timer = nil
    end
  end,
})
