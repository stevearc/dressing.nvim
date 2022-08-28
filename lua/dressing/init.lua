local patch = require("dressing.patch")

local M = {}

M.setup = function(opts)
  require("dressing.config").update(opts)
  patch.all()
end

---Patch all the vim.ui methods
M.patch = function()
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
