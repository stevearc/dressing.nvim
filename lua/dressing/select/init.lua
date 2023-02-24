local global_config = require("dressing.config")
local patch = require("dressing.patch")

local function get_backend(config)
  local backends = config.backend
  if type(backends) ~= "table" then
    backends = { backends }
  end
  for _, backend in ipairs(backends) do
    local ok, mod = pcall(require, string.format("dressing.select.%s", backend))
    if ok and mod.is_supported() then
      return mod, backend
    end
  end
  return require("dressing.select.builtin"), "builtin"
end

local function sanitize_line(line)
  return string.gsub(tostring(line), "\n", " ")
end

local function with_sanitize_line(fn)
  return function(...)
    return sanitize_line(fn(...))
  end
end

-- use schedule_wrap to avoid a bug when vim opens
-- (see https://github.com/stevearc/dressing.nvim/issues/15)
-- also to prevent focus problems for providers
-- (see https://github.com/stevearc/dressing.nvim/issues/59)
return vim.schedule_wrap(function(items, opts, on_choice)
  vim.validate({
    items = {
      items,
      function(a)
        return type(a) == "table" and vim.tbl_islist(a)
      end,
      "list-like table",
    },
    on_choice = { on_choice, "function", false },
  })
  opts = opts or {}
  local config = global_config.get_mod_config("select", opts, items)

  if not config.enabled then
    return patch.original_mods.select(items, opts, on_choice)
  end

  opts.prompt = sanitize_line(opts.prompt or "Select one of:")
  if config.trim_prompt and opts.prompt:sub(-1, -1) == ":" then
    opts.prompt = opts.prompt:sub(1, -2)
  end

  local format_override = config.format_item_override[opts.kind]
  if format_override then
    opts.format_item = with_sanitize_line(format_override)
  elseif opts.format_item then
    -- format_item doesn't *technically* have to return a string for the
    -- core implementation. We should maintain compatibility by wrapping the
    -- return value with tostring
    opts.format_item = with_sanitize_line(opts.format_item)
  else
    opts.format_item = sanitize_line
  end

  local backend, name = get_backend(config)
  local winid = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(winid)
  backend.select(
    config[name],
    items,
    opts,
    vim.schedule_wrap(function(...)
      if vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_win_set_cursor(winid, cursor)
      end
      on_choice(...)
    end)
  )
end)
