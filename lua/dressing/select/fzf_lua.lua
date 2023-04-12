local M = {}

M.is_supported = function()
  return pcall(require, "fzf-lua.providers.ui_select")
end

M.select = function(config, items, opts, on_choice)
  if config then
    vim.notify_once(
      "Deprecated: dressing config for fzf_lua has been removed in favor of using the built-in fzf-lua vim.ui.select implementation.\nRemove the fzf_lua key from dressing.setup()",
      vim.log.levels.WARN
    )
  end
  return require("fzf-lua.providers.ui_select").ui_select(items, opts, on_choice)
end

return M
