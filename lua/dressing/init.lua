local config = require("dressing.config")

local M = {}

M.setup = function(opts)
  config.update(opts)
  -- Wait until vim has fully started up before we show deprecation warnings
  vim.defer_fn(function()
    if config.input.prompt_buffer then
      vim.notify(
        "dressing.nvim option 'input.prompt_buffer = true' is deprecated and will be removed in a future version. If you want it to continue to be supported please file an issue with your use case: https://github.com/stevearc/dressing.nvim/issues/new",
        vim.log.levels.WARN,
        {}
      )
    end
  end, 100)
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
