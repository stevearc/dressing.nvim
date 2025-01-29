local M = {}

M.is_supported = function()
  return pcall(require, "snacks.picker")
end

M.select = function(_, items, opts, on_choice)
  return require("snacks.picker.select").select(items, opts, on_choice)
end

return M
