-- Run this test with :source %

vim.cmd([[
  highlight RBP1 guibg=Red ctermbg=red
  highlight RBP2 guibg=Yellow ctermbg=yellow
  highlight RBP3 guibg=Green ctermbg=green
  highlight RBP4 guibg=Blue ctermbg=blue
]])
local rainbow_levels = 4
local function rainbow_hl(cmdline)
  local ret = {}
  local lvl = 0
  for i = 1, string.len(cmdline) do
    local char = string.sub(cmdline, i, i)
    if char == "(" then
      table.insert(ret, { i - 1, i, string.format("RBP%d", (lvl % rainbow_levels) + 1) })
      lvl = lvl + 1
    elseif char == ")" then
      lvl = lvl - 1
      table.insert(ret, { i - 1, i, string.format("RBP%d", (lvl % rainbow_levels) + 1) })
    end
  end
  return ret
end

vim.ui.input({
  prompt = "Rainbow: ",
  default = "((()(())))",
  highlight = rainbow_hl,
}, function() end)
