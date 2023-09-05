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

local function close_window()
  local callback = _callback
  local items = _items
  clear_callback()
  vim.api.nvim_win_close(0, true)
  return callback, items
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
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].bufhidden = "wipe"
  for k, v in pairs(config.buf_options) do
    vim.bo[bufnr][k] = v
  end
  local lines = {}
  local highlights = {}
  local max_width = 1
  for idx, item in ipairs(items) do
    local prefix = ""
    if config.show_numbers then
      prefix = "[" .. idx .. "] "
      table.insert(highlights, { #lines, prefix:len() })

      vim.api.nvim_buf_set_keymap(bufnr, "n", tostring(idx), "", {
        callback = function()
          local callback, local_items = close_window()
          local target_item = local_items[idx]
          callback(target_item, idx)
        end,
      })
    end
    local line = prefix .. opts.format_item(item)
    max_width = math.max(max_width, vim.api.nvim_strwidth(line))
    table.insert(lines, line)
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
  vim.bo[bufnr].modifiable = false
  local ns = vim.api.nvim_create_namespace("DressingSelect")
  for _, hl in ipairs(highlights) do
    local lnum, end_col = unpack(hl)
    vim.api.nvim_buf_add_highlight(bufnr, ns, "DressingSelectIdx", lnum, 0, end_col)
  end
  local width = util.calculate_width(config.relative, max_width, config, 0)
  local height = util.calculate_height(config.relative, #lines, config, 0)
  local row = util.calculate_row(config.relative, height, 0)
  local col = util.calculate_col(config.relative, width, 0)
  local winopt = {
    relative = config.relative,
    anchor = "NW",
    row = row,
    col = col,
    border = config.border,
    width = width,
    height = height,
    zindex = 150,
    style = "minimal",
  }
  if vim.fn.has("nvim-0.9") == 1 then
    winopt.title = opts.prompt:gsub("^%s*(.-)%s*$", " %1 ")
    winopt.title_pos = config.title_pos or "center"
  end
  winopt = config.override(winopt) or winopt
  local winid = vim.api.nvim_open_win(bufnr, true, winopt)
  for option, value in pairs(config.win_options) do
    vim.api.nvim_set_option_value(option, value, { scope = "local", win = winid })
  end
  vim.bo[bufnr].filetype = "DressingSelect"
  if vim.fn.has("nvim-0.9") == 0 then
    util.add_title_to_win(winid, opts.prompt)
  end

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
