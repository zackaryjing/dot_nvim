-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste System Clipboard" })
vim.keymap.set("x", "<leader>y", '"+y', { desc = "Yank Selection to System Clipboard" })
vim.keymap.set("i", "<Esc>", function()
  vim.cmd("noh")
  LazyVim.cmp.actions.snippet_stop()
  return "<Esc>" .. (vim.api.nvim_get_current_line():match("^%s+$") and "<Right>" or "")
end, { expr = true, desc = "Escape and Preserve Blank-Line Indent" })
vim.keymap.set("n", "o", "o <BS>", { desc = "Add Line Below and Preserve Indent" })
vim.keymap.set("n", "O", "O <BS>", { desc = "Add Line Above and Preserve Indent" })

local function cpp_print_command(opts, include_label)
  local start_row, start_col, end_row, end_col

  if opts.range == 0 then
    start_row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local line = vim.api.nvim_get_current_line()
    local indent = line:match("^%s*")
    local expression = vim.trim(line)
    local label = expression:gsub("\\", "\\\\"):gsub('"', '\\"')
    local statement = include_label and ('cout << "' .. label .. ': " << ' .. expression .. " << endl;")
      or ("cout << " .. expression .. " << endl;")

    vim.api.nvim_set_current_line(indent .. statement)
    return
  end

  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  start_row, start_col = start_pos[2] - 1, start_pos[3] - 1
  end_row, end_col = end_pos[2] - 1, end_pos[3] - 1

  if start_row ~= end_row then
    vim.notify("Wvar and Wline only support a single-line selection", vim.log.levels.WARN)
    return
  end

  local line = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, false)[1]
  end_col = end_col + #vim.fn.strcharpart(line:sub(end_col + 1), 0, 1)

  local expression = table.concat(vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {}), "\n")
  local label = expression:gsub("\\", "\\\\"):gsub('"', '\\"')
  local statement = include_label and ('cout << "' .. label .. ': " << ' .. expression .. " << endl;")
    or ("cout << " .. expression .. " << endl;")

  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, { statement })
end

vim.api.nvim_create_user_command("Wvar", function(opts)
  cpp_print_command(opts, true)
end, { desc = "Print selected C++ variable with its name", range = true })

vim.api.nvim_create_user_command("Wline", function(opts)
  cpp_print_command(opts, false)
end, { desc = "Print selected C++ expression", range = true })

local function replace_current_line(replacements)
  local line = vim.api.nvim_get_current_line()
  for from, to in pairs(replacements) do
    line = line:gsub(vim.pesc(from), to)
  end
  vim.api.nvim_set_current_line(line)
end

vim.api.nvim_create_user_command("Gi", function()
  replace_current_line({ ["["] = "{", ["]"] = "}" })
end, { desc = "Replace brackets with braces on the current line" })

vim.api.nvim_create_user_command("Gv", function()
  replace_current_line({ ["["] = "temp_vector({", ["]"] = "})" })
end, { desc = "Wrap brackets with temp_vector on the current line" })

vim.api.nvim_create_user_command("Gj", function()
  replace_current_line({ ["["] = "vec![" })
end, { desc = "Replace brackets with Rust vec macro on the current line" })
