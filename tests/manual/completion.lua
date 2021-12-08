-- Run this test with :source %

local idx = 1
local cases = {
  {
    prompt = "Complete file: ",
    completion = "file",
  },
  {
    prompt = "Complete cmd: ",
    completion = "command",
  },
  {
    prompt = "Complete custom: ",
    completion = "custom,CustomComplete",
  },
  {
    prompt = "Complete customlist: ",
    completion = "customlist,CustomCompleteList",
  },
}

vim.cmd([[
function! CustomComplete(arglead, cmdline, cursorpos)
  return "first\nsecond\nthird"
endfunction

function! CustomCompleteList(arglead, cmdline, cursorpos)
  return ['first', 'second', 'third']
endfunction
]])

local function next()
  local opts = cases[idx]
  if opts then
    idx = idx + 1
    vim.ui.input(opts, next)
  end
end

next()

-- Uncomment this to test opening a modal while the previous one is open
-- vim.ui.input(cases[1], function(text)
--   print(text)
-- end)
-- vim.defer_fn(function()
--   vim.ui.input(cases[2], function(text)
--     print(text)
--   end)
-- end, 2000)
