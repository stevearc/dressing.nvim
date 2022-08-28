local all_modules = { "input", "select" }

local M = {}

-- For Neovim before 0.6
if not vim.ui then
  vim.ui = {}
end

local enabled_mods = {}
M.original_mods = {}

for _, key in ipairs(all_modules) do
  M.original_mods[key] = vim.ui[key]
  vim.ui[key] = function(...)
    local enabled = enabled_mods[key]
    if enabled == nil then
      enabled = require("dressing.config")[key].enabled
    end
    if enabled then
      require(string.format("dressing.%s", key))(...)
    else
      return M.original_mods[key](...)
    end
  end
end

---Patch or unpatch all vim.ui methods
---@param enabled? boolean When nil, use the default from config
M.all = function(enabled)
  for _, name in ipairs(all_modules) do
    M.mod(name, enabled)
  end
end

---@param name string
---@param enabled? boolean When nil, use the default from config
M.mod = function(name, enabled)
  enabled_mods[name] = enabled
end

return M
