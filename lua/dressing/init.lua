local config = require("dressing.config")
local patch = require("dressing.patch")

local M = {}

M.setup = function(opts)
  config.update(opts)
  patch.all()
end

M.patch = function()
  patch.all()
end

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
