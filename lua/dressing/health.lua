local config = require("dressing.config")
local patch = require("dressing.patch")

local M = {}

-- The "report_" functions have been deprecated, so use the new ones if defined.
---@diagnostic disable: deprecated
local health_start = vim.health.start or vim.health.report_start
local health_warn = vim.health.warn or vim.health.report_warn
local health_ok = vim.health.ok or vim.health.report_ok

M.check = function()
  health_start("dressing.nvim")
  if patch.is_enabled("input") then
    health_ok("vim.ui.input active")
  else
    health_warn("vim.ui.input not enabled")
  end

  if patch.is_enabled("select") then
    local _, name = require("dressing.select").get_backend(config.select.backend)
    health_ok("vim.ui.select active: " .. name)
  else
    health_warn("vim.ui.select not enabled")
  end
end

return M
