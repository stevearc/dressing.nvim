local M = {}

local function is_float(value)
  local _, p = math.modf(value)
  return p ~= 0
end

local function calc_float(value, max_value)
  if value and is_float(value) then
    return math.min(max_value, value * max_value)
  else
    return value
  end
end

local function calc_list(values, max_value, aggregator, limit)
  local ret = limit
  if type(values) == "table" then
    for _, v in ipairs(values) do
      ret = aggregator(ret, calc_float(v, max_value))
    end
    return ret
  else
    ret = aggregator(ret, calc_float(values, max_value))
  end
  return ret
end

local function calculate_dim(desired_size, size, min_size, max_size, total_size)
  local ret = calc_float(size, total_size)
  local min_val = calc_list(min_size, total_size, math.max, 1)
  local max_val = calc_list(max_size, total_size, math.min, total_size)
  if not ret then
    if not desired_size then
      ret = (min_val + max_val) / 2
    else
      ret = calc_float(desired_size, total_size)
    end
  end
  ret = math.min(ret, max_val)
  ret = math.max(ret, min_val)
  return math.floor(ret)
end

local function get_max_width(relative, winid)
  if relative == "editor" then
    return vim.o.columns
  else
    return vim.api.nvim_win_get_width(winid or 0)
  end
end

local function get_max_height(relative, winid)
  if relative == "editor" then
    return vim.o.lines - vim.o.cmdheight
  else
    return vim.api.nvim_win_get_height(winid or 0)
  end
end

M.calculate_col = function(relative, width, winid)
  if relative == "cursor" then
    return 0
  else
    return math.floor((get_max_width(relative, winid) - width) / 2)
  end
end

M.calculate_row = function(relative, height, winid)
  if relative == "cursor" then
    return 0
  else
    return math.floor((get_max_height(relative, winid) - height) / 2)
  end
end

M.calculate_width = function(relative, desired_width, config, winid)
  return calculate_dim(
    desired_width,
    config.width,
    config.min_width,
    config.max_width,
    get_max_width(relative, winid)
  )
end

M.calculate_height = function(relative, desired_height, config, winid)
  return calculate_dim(
    desired_height,
    config.height,
    config.min_height,
    config.max_height,
    get_max_height(relative, winid)
  )
end

local winid_map = {}
M.add_title_to_win = function(winid, title, opts)
  opts = opts or {}
  opts.align = opts.align or "center"
  if not vim.api.nvim_win_is_valid(winid) then
    return
  end
  -- HACK to force the parent window to position itself
  -- See https://github.com/neovim/neovim/issues/13403
  vim.cmd("redraw")
  local width = math.min(vim.api.nvim_win_get_width(winid) - 4, 2 + vim.api.nvim_strwidth(title))
  local title_winid = winid_map[winid]
  local bufnr
  if title_winid and vim.api.nvim_win_is_valid(title_winid) then
    vim.api.nvim_win_set_width(title_winid, width)
    bufnr = vim.api.nvim_win_get_buf(title_winid)
  else
    bufnr = vim.api.nvim_create_buf(false, true)
    local col = 1
    if opts.align == "center" then
      col = math.floor((vim.api.nvim_win_get_width(winid) - width) / 2)
    elseif opts.align == "right" then
      col = vim.api.nvim_win_get_width(winid) - 1 - width
    elseif opts.align ~= "left" then
      vim.notify(
        string.format("Unknown dressing window title alignment: '%s'", opts.align),
        vim.log.levels.ERROR
      )
    end
    title_winid = vim.api.nvim_open_win(bufnr, false, {
      relative = "win",
      win = winid,
      width = width,
      height = 1,
      row = -1,
      col = col,
      focusable = false,
      zindex = 151,
      style = "minimal",
      noautocmd = true,
    })
    winid_map[winid] = title_winid
    vim.api.nvim_set_option_value(
      "winblend",
      vim.wo[winid].winblend,
      { scope = "local", win = title_winid }
    )
    vim.bo[bufnr].bufhidden = "wipe"
    vim.cmd(string.format(
      [[
      autocmd WinClosed %d ++once lua require('dressing.util')._on_win_closed(%d)
    ]],
      winid,
      winid
    ))
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, { " " .. title:gsub("\n", " ") .. " " })
  local ns = vim.api.nvim_create_namespace("DressingWindow")
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  vim.api.nvim_buf_add_highlight(bufnr, ns, "FloatTitle", 0, 0, -1)
end

M._on_win_closed = function(winid)
  local title_winid = winid_map[winid]
  if title_winid and vim.api.nvim_win_is_valid(title_winid) then
    vim.api.nvim_win_close(title_winid, true)
  end
  winid_map[winid] = nil
end

M.schedule_wrap_before_vimenter = function(func)
  if vim.g.is_test then
    return func
  end
  return function(...)
    if vim.v.vim_did_enter == 0 then
      return vim.schedule_wrap(func)(...)
    else
      return func(...)
    end
  end
end

return M
