-- Run this test with :source %

local function run_test(backend)
  local config = require("dressing.config")
  local prev_backend = config.select.backend
  config.select.backend = backend
  vim.ui.select({ "first", "second", "third" }, {
    prompt = "Make selection: ",
    kind = "test",
  }, function(item, lnum)
    if item and lnum then
      vim.notify(string.format("selected '%s' (idx %d)", item, lnum), vim.log.levels.INFO)
    else
      vim.notify("Selection canceled", vim.log.levels.INFO)
    end
    config.select.backend = prev_backend
  end)
end

-- Replace this with the desired backend to test
run_test("fzf_lua")
