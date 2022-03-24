local config = require("dressing.config")

local all_modules = { "input", "select" }

local M = {}

-- For Neovim before 0.6
if not vim.ui then
  vim.ui = {}
end

M.original_mods = {}

M.all = function(enabled)
  for _, name in ipairs(all_modules) do
    M.mod(name, enabled)
  end
end

M.mod = function(name, enabled)
  if enabled == nil then
    enabled = config[name].enabled
  end
  if enabled then
    if M.original_mods[name] == nil then
      M.original_mods[name] = vim.ui[name]
    end
    vim.ui[name] = require(string.format("dressing.%s", name))
  else
    local mod = require(string.format("dressing.%s", name))
    if vim.ui[name] == mod then
      vim.ui[name] = M.original_mods[name]
    end
  end
end

return M
