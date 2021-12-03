local global_config = require("dressing.config")
local util = require("dressing.util")

local function clear_callbacks()
  _G.dressing_prompt_confirm = function() end
  _G.dressing_prompt_cancel = function() end
  _G.dressing_prompt_hl = function() end
end

clear_callbacks()

return function(opts, on_confirm)
  vim.validate({
    on_confirm = { on_confirm, "function", false },
  })

  opts = opts or {}
  local config = global_config.get_mod_config("input", opts)

  local bufnr = vim.api.nvim_create_buf(false, true)
  local prompt = opts.prompt or config.default_prompt
  local width = util.calculate_width(config.prefer_width + vim.api.nvim_strwidth(prompt), config)
  local winopt = {
    relative = config.relative,
    anchor = config.anchor,
    row = config.row,
    col = config.col,
    border = config.border,
    width = width,
    height = 1,
    zindex = 150,
    style = "minimal",
  }
  local winnr = vim.api.nvim_open_win(bufnr, true, winopt)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "prompt")
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.fn.prompt_setprompt(bufnr, prompt)
  _G.dressing_prompt_confirm = function(text)
    clear_callbacks()
    vim.api.nvim_win_close(winnr, true)
    on_confirm(text)
  end
  _G.dressing_prompt_cancel = function()
    clear_callbacks()
    vim.api.nvim_win_close(winnr, true)
    on_confirm(nil)
  end
  if opts.highlight then
    _G.dressing_prompt_hl = function()
      local text = vim.api.nvim_buf_get_lines(bufnr, 0, 1, true)[1]
      local ns = vim.api.nvim_create_namespace("DressingHl")
      local highlights
      if type(opts.highlight) == "function" then
        highlights = opts.highlight(text)
      else
        highlights = vim.fn[opts.highlight](text)
      end
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
      for _, highlight in ipairs(highlights) do
        local start = highlight[1]
        local stop = highlight[2]
        local group = highlight[3]
        vim.api.nvim_buf_add_highlight(bufnr, ns, group, 0, start, stop)
      end
    end
    vim.cmd([[
        autocmd TextChanged <buffer> lua dressing_prompt_hl()
        autocmd TextChangedI <buffer> lua dressing_prompt_hl()
    ]])
  end
  -- Would prefer to use v:lua directly here, but it doesn't work :(
  vim.fn.prompt_setcallback(bufnr, "dressing#prompt_confirm")
  vim.fn.prompt_setinterrupt(bufnr, "dressing#prompt_cancel")
  vim.cmd([[
      autocmd BufLeave <buffer> call dressing#prompt_cancel()
  ]])
  vim.cmd("startinsert!")
  if opts.default then
    vim.fn.feedkeys(opts.default)
  end
  _G.dressing_prompt_hl()
end
