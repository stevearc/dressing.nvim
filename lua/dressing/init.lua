local config = require("dressing.config")

local M = {}

M.setup = function(opts)
  config.update(opts)
end

local original_input
local original_select

M.patch = function()
  -- For Neovim before 0.6
  if not vim.ui then
    vim.ui = {}
  end
  if not original_input then
    original_input = vim.ui.input
    original_select = vim.ui.select
  end
  vim.ui.input = require("dressing.input")
  vim.ui.select = require("dressing.select")
end

M.unpatch = function()
  vim.ui.input = original_input
  vim.ui.select = original_select
end

return M
