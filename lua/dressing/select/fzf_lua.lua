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
  return ui_select.ui_select(items, opts, on_choice)
end

return M
