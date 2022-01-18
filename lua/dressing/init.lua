local config = require("dressing.config")

local M = {}
local all_modules = { "input", "select" }
local original_mods = {}

M.setup = function(opts)
  config.update(opts)
  for _, name in ipairs(all_modules) do
    if not config[name].enabled then
      M.unpatch(name)
    end
  end
end

M.patch = function()
  -- For Neovim before 0.6
  if not vim.ui then
    vim.ui = {}
  end

  for _, name in ipairs(all_modules) do
    if config[name].enabled and original_mods[name] == nil then
      original_mods[name] = vim.ui[name]
      vim.ui[name] = require(string.format("dressing.%s", name))
    end
  end
end

M.unpatch = function(names)
  if not names then
    names = all_modules
  elseif type(names) ~= "table" then
    names = { names }
  end
  for _, name in ipairs(names) do
    local mod = require(string.format("dressing.%s", name))
    if vim.ui[name] == mod then
      vim.ui[name] = original_mods[name]
    end
  end
end

return M
