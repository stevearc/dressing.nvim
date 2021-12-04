local global_config = require("dressing.config")
local util = require("dressing.util")

local function clear_callbacks()
  _G.dressing_prompt_confirm = function() end
  _G.dressing_prompt_hl = function() end
end

clear_callbacks()

return function(opts, on_confirm)
  vim.validate({
    on_confirm = { on_confirm, "function", false },
  })

  opts = opts or {}
  if type(opts) ~= "table" then
    opts = { prompt = tostring(opts) }
  end
  local config = global_config.get_mod_config("input", opts)

  local start_in_insert = vim.api.nvim_get_mode().mode == "i"
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
  local keyopts = { silent = true, noremap = true }
  vim.api.nvim_buf_set_keymap(
    bufnr,
    "i",
    "<Esc>",
    "<cmd>lua dressing_prompt_confirm()<CR>",
    keyopts
  )
  vim.fn.prompt_setprompt(bufnr, prompt)
  -- Would prefer to use v:lua directly here, but it doesn't work :(
  vim.fn.prompt_setcallback(bufnr, "dressing#prompt_confirm")
  vim.fn.prompt_setinterrupt(bufnr, "dressing#prompt_cancel")
  _G.dressing_prompt_confirm = function(text)
    clear_callbacks()
    vim.api.nvim_win_close(winnr, true)
    if not start_in_insert then
      vim.cmd("stopinsert")
      -- stopinsert will move the cursor back 1. We need to move it forward 1 to
      -- put it in the place you were when you opened the modal.
      local cursor = vim.api.nvim_win_get_cursor(0)
      cursor[2] = cursor[2] + 1
      vim.api.nvim_win_set_cursor(0, cursor)
    end
    on_confirm(text)
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
  vim.cmd([[
      autocmd BufLeave <buffer> ++nested ++once lua dressing_prompt_confirm()
  ]])
  vim.cmd("startinsert!")
  if opts.default then
    vim.api.nvim_feedkeys(opts.default, "n", false)
  end
  _G.dressing_prompt_hl()
end
