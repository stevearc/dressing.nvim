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

return M
