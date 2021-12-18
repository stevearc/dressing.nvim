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

local function calculate_dim(desired_size, size, min_size, max_size, total_size)
  local ret = calc_float(size, total_size)
  if not ret then
    ret = calc_float(desired_size, total_size)
  end
  ret = math.min(ret, calc_float(max_size, total_size) or total_size)
  ret = math.max(ret, calc_float(min_size, total_size) or 1)
  return math.floor(ret)
end

M.calculate_width = function(desired_width, config)
  return calculate_dim(
    desired_width,
    config.width,
    config.min_width,
    config.max_width,
    vim.o.columns
  )
end

M.calculate_height = function(desired_height, config)
  return calculate_dim(
    desired_height,
    config.height,
    config.min_height,
    config.max_height,
    vim.o.lines - vim.o.cmdheight
  )
end

local winid_map = {}
M.add_title_to_win = function(winid, title, opts)
  opts = opts or {}
  opts.align = opts.align or "center"
  -- Create the title window once the main window is placed.
  -- Have to defer here or the title will be in the wrong location
  vim.defer_fn(function()
    if not vim.api.nvim_win_is_valid(winid) then
      return
    end
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
      vim.api.nvim_win_set_option(
        title_winid,
        "winblend",
        vim.api.nvim_win_get_option(winid, "winblend")
      )
      vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
      vim.cmd(string.format(
        [[
      autocmd WinClosed %d ++once lua require('dressing.util')._on_win_closed(%d)
    ]],
        winid,
        winid
      ))
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, { " " .. title .. " " })
    local ns = vim.api.nvim_create_namespace("DressingWindow")
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    vim.api.nvim_buf_add_highlight(bufnr, ns, "FloatTitle", 0, 0, -1)
  end, 10)
end

M._on_win_closed = function(winid)
  local title_winid = winid_map[winid]
  if title_winid and vim.api.nvim_win_is_valid(title_winid) then
    vim.api.nvim_win_close(title_winid, true)
  end
  winid_map[winid] = nil
end

return M
