local map_util = require("dressing.map_util")
local util = require("dressing.util")
local M = {}

local keymaps = {
  {
    desc = "Close vim.ui.select without a result",
    plug = "<Plug>DressingSelect:Close",
    rhs = function()
      M.cancel()
    end,
  },
  {
    desc = "Select the current vim.ui.select item under the cursor",
    plug = "<Plug>DressingSelect:Confirm",
    rhs = function()
      M.choose()
    end,
  },
}

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
  if vim.fn.hlID("DressingSelectText") ~= 0 then
    vim.notify(
      'DressingSelectText highlight group is deprecated. Set winhighlight="NormalFloat:MyHighlightGroup" instead',
      vim.log.levels.WARN
    )
  end
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
  local width = util.calculate_width(config.relative, max_width, config, 0)
  local height = util.calculate_height(config.relative, #lines, config, 0)
  local row = util.calculate_row(config.relative, height, 0)
  local col = util.calculate_col(config.relative, width, 0)
  local winopt = {
    relative = config.relative,
    anchor = config.anchor,
    row = row,
    col = col,
    border = config.border,
    width = width,
    height = height,
    zindex = 150,
    style = "minimal",
  }
  winopt = config.override(winopt) or winopt
  local winnr = vim.api.nvim_open_win(bufnr, true, winopt)
  vim.api.nvim_win_set_option(winnr, "winblend", config.winblend)
  vim.api.nvim_win_set_option(winnr, "winhighlight", config.winhighlight)
  vim.api.nvim_win_set_option(winnr, "cursorline", true)
  pcall(vim.api.nvim_win_set_option, winnr, "cursorlineopt", "both")
  vim.api.nvim_buf_set_option(bufnr, "filetype", "DressingSelect")
  util.add_title_to_win(winnr, opts.prompt)

  map_util.create_plug_maps(bufnr, keymaps)
  map_util.create_maps_to_plug(bufnr, "n", config.mappings, "DressingSelect:")
  vim.api.nvim_create_autocmd("BufLeave", {
    desc = "Cancel vim.ui.select",
    buffer = bufnr,
    nested = true,
    once = true,
    callback = M.cancel,
  })
end

local function close_window()
  local callback = _callback
  local items = _items
  clear_callback()
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
