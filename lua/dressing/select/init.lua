local global_config = require("dressing.config")

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

return function(items, opts, on_choice)
  vim.validate({
    items = { items, "table", false },
    on_choice = { on_choice, "function", false },
  })
  opts = opts or {}
  local config = global_config.get_mod_config("select", opts)
  opts.prompt = opts.prompt or "Select one of:"
  opts.format_item = opts.format_item or tostring

  local backend, name = get_backend(config)
  backend.select(config[name], items, opts, on_choice)
end
