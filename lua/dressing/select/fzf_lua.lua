local M = {}

M.is_supported = function()
  return pcall(require, "fzf-lua.providers.ui_select")
end

M.select = function(config, items, opts, on_choice)
  local ui_select = require("fzf-lua.providers.ui_select")
  if config and not vim.tbl_isempty(config) then
    -- Registering then unregistering sets the config options
    ui_select.register(config, true)
    ui_select.deregister(nil, true, true)
  end
  -- Defer the callback to allow the mode to fully switch back to normal after the fzf terminal
  local deferred_on_choice = function(...)
    local args = vim.F.pack_len(...)
    vim.defer_fn(function()
      on_choice(vim.F.unpack_len(args))
    end, 10)
  end
  return ui_select.ui_select(items, opts, deferred_on_choice)
end

return M
