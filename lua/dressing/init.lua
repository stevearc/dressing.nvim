local config = require("dressing.config")

local M = {}

M.setup = function(opts)
  config.update(opts)
end

M.patch = function()
  -- For Neovim before 0.6
  if not vim.ui then
    vim.ui = {}
  end
  vim.ui.input = require("dressing.input")
  vim.ui.select = require("dressing.select")
end

return M
