local util = require("dressing.util")
local M = {}

M.is_supported = function()
  return true
end

local _callback = function(item, idx) end
local _items = {}
local function clear_callback()
  _callback = function() end
  _items = {}
end

M.select = function(config, items, opts, on_choice)
  _callback = on_choice
  _items = items
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  local lines = {}
  local max_width = 1
  for _, item in ipairs(items) do
    local line = opts.format_item(item)
    max_width = math.max(max_width, vim.api.nvim_strwidth(line))
    table.insert(lines, line)
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  local width = util.calculate_width(max_width, config)
  local winopt = {
    relative = config.relative,
    anchor = config.anchor,
    row = config.row,
    col = config.col,
    border = config.border,
    width = width,
    height = util.calculate_height(#lines, config),
    zindex = 150,
    style = "minimal",
  }
  local winnr = vim.api.nvim_open_win(bufnr, true, winopt)
  vim.api.nvim_win_set_option(winnr, "winblend", config.winblend)
  vim.api.nvim_win_set_option(winnr, "cursorline", true)
  pcall(vim.api.nvim_win_set_option, winnr, "cursorlineopt", "both")

  -- Create the title window once the main window is placed.
  -- Have to defer here or the title will be in the wrong location
  vim.defer_fn(function()
    local titlebuf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(titlebuf, 0, -1, true, { " " .. opts.prompt })
    vim.api.nvim_buf_set_option(titlebuf, "bufhidden", "wipe")
    local prompt_width = math.min(width, 2 + vim.api.nvim_strwidth(opts.prompt))
    local titlewin = vim.api.nvim_open_win(titlebuf, false, {
      relative = "win",
      win = winnr,
      width = prompt_width,
      height = 1,
      row = -1,
      col = (width - prompt_width) / 2,
      focusable = false,
      zindex = 151,
      style = "minimal",
      noautocmd = true,
    })
    vim.api.nvim_buf_set_var(bufnr, "dressing_title_window", titlewin)
    vim.api.nvim_win_set_option(titlewin, "winblend", config.winblend)
  end, 5)

  local function map(lhs, rhs)
    vim.api.nvim_buf_set_keymap(bufnr, "n", lhs, rhs, { silent = true, noremap = true })
  end

  map("<CR>", [[<cmd>lua require('dressing.select.builtin').choose()<CR>]])
  map("<C-c>", [[<cmd>lua require('dressing.select.builtin').cancel()<CR>]])
  map("<Esc>", [[<cmd>lua require('dressing.select.builtin').cancel()<CR>]])
  vim.cmd([[
    autocmd BufLeave <buffer> ++nested ++once lua require('dressing.select.builtin').cancel()
  ]])
end

local function close_window()
  local callback = _callback
  local items = _items
  clear_callback()
  local ok, titlewin = pcall(vim.api.nvim_buf_get_var, 0, "dressing_title_window")
  if ok and vim.api.nvim_win_is_valid(titlewin) then
    vim.api.nvim_win_close(titlewin, true)
  end
  vim.api.nvim_win_close(0, true)
  return callback, items
end

M.choose = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local idx = cursor[1]
  local callback, items = close_window()
  local item = items[idx]
  callback(item, idx)
end

M.cancel = function()
  local callback = close_window()
  callback(nil, nil)
end

return M
