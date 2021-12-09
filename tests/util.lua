require("plenary.async").tests.add_to_env()
local M = {}

M.feedkeys = function(actions, timestep)
  timestep = timestep or 10
  a.util.sleep(timestep)
  for _, action in ipairs(actions) do
    a.util.sleep(timestep)
    local escaped = vim.api.nvim_replace_termcodes(action, true, false, true)
    vim.api.nvim_feedkeys(escaped, "m", true)
  end
  a.util.sleep(timestep)
  -- process pending keys until the queue is empty.
  -- Note that this will exit insert mode.
  vim.api.nvim_feedkeys("", "x", true)
  a.util.sleep(timestep)
end

return M
