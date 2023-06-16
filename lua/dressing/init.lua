local patch = require("dressing.patch")

local M = {}

M.setup = function(opts)
  require("dressing.config").update(opts)
  M.patch()
end

---Patch all the vim.ui methods
M.patch = function()
  if vim.fn.has("nvim-0.8") == 0 then
    vim.notify_once(
      "dressing has dropped support for Neovim <0.8. Please use the nvim-0.7 branch or upgrade Neovim",
      vim.log.levels.ERROR
    )
    return
  end
  patch.all()
end

---Unpatch all the vim.ui methods
---@param names? string[] Names of vim.ui modules to unpatch
M.unpatch = function(names)
  if not names then
    return patch.all(false)
  elseif type(names) ~= "table" then
    names = { names }
  end
  for _, name in ipairs(names) do
    patch.mod(name, false)
  end
end

return M
