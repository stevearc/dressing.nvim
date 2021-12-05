local global_config = require("dressing.config")
local util = require("dressing.util")
local M = {}

local context = {
  opts = nil,
  on_confirm = nil,
  winid = nil,
}

M.confirm = function(text)
  if not context.on_confirm then
    return
  end
  local ctx = context
  context = {}
  vim.api.nvim_win_close(ctx.winid, true)
  vim.cmd("stopinsert")
  -- stopinsert will move the cursor back 1. We need to move it forward 1 to
  -- put it in the place you were when you opened the modal.
  local cursor = vim.api.nvim_win_get_cursor(0)
  cursor[2] = cursor[2] + 1
  vim.api.nvim_win_set_cursor(0, cursor)
  vim.schedule_wrap(ctx.on_confirm)(text)
end

M.highlight = function()
  if not context.opts or not context.opts.highlight then
    return
  end
  local bufnr = vim.api.nvim_win_get_buf(context.winid)
  local opts = context.opts
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

local function split(string, pattern)
  local ret = {}
  for token in string.gmatch(string, "[^" .. pattern .. "]+") do
    table.insert(ret, token)
  end
  return ret
end

M.completefunc = function(findstart, base)
  if not context.opts or not context.opts.completion then
    return findstart == 1 and 0 or {}
  end
  if findstart == 1 then
    return vim.api.nvim_strwidth(context.opts.prompt)
  else
    local completion = context.opts.completion
    local pieces = split(completion, ",")
    if pieces[1] == "custom" or pieces[1] == "customlist" then
      local vimfunc = pieces[2]
      local ret = vim.fn[vimfunc](base, base, vim.fn.strlen(base))
      print(vim.inspect(ret))
      if pieces[1] == "custom" then
        ret = split(ret, "\n")
      end
      return ret
    else
      local ok, result = pcall(vim.fn.getcompletion, base, context.opts.completion)
      if ok then
        return result
      else
        vim.api.nvim_err_writeln(
          string.format("dressing.nvim: unsupported completion method '%s'", completion)
        )
        return {}
      end
    end
  end
end

_G.dressing_input_complete = M.completefunc

M.trigger_completion = function()
  if vim.fn.pumvisible() == 1 then
    return vim.api.nvim_replace_termcodes("<C-n>", true, false, true)
  else
    return vim.api.nvim_replace_termcodes("<C-x><C-u>", true, false, true)
  end
end

setmetatable(M, {
  __call = function(_, opts, on_confirm)
    vim.validate({
      on_confirm = { on_confirm, "function", false },
    })
    opts = opts or {}
    if type(opts) ~= "table" then
      opts = { prompt = tostring(opts) }
    end
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
      style = "minimal",
    }
    local winnr
    if context.winid and vim.api.nvim_win_is_valid(context.winid) then
      winnr = context.winid
      vim.schedule(context.on_confirm)
      vim.api.nvim_win_set_width(winnr, width)
      bufnr = vim.api.nvim_win_get_buf(winnr)
    else
      winnr = vim.api.nvim_open_win(bufnr, true, winopt)
    end
    context = {
      winid = winnr,
      on_confirm = on_confirm,
      opts = opts,
    }
    vim.api.nvim_buf_set_option(bufnr, "buftype", "prompt")
    vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
    local keyopts = { silent = true, noremap = true }
    vim.api.nvim_buf_set_keymap(
      bufnr,
      "i",
      "<Esc>",
      ":lua require('dressing.input').confirm()<CR>",
      keyopts
    )
    vim.fn.prompt_setprompt(bufnr, prompt)
    -- Would prefer to use v:lua directly here, but it doesn't work :(
    vim.fn.prompt_setcallback(bufnr, "dressing#prompt_confirm")
    vim.fn.prompt_setinterrupt(bufnr, "dressing#prompt_cancel")
    if opts.highlight then
      vim.cmd([[
        autocmd TextChanged <buffer> lua require('dressing.input').highlight()
        autocmd TextChangedI <buffer> lua require('dressing.input').highlight()
      ]])
    end
    if opts.completion then
      vim.api.nvim_buf_set_option(bufnr, "completefunc", "v:lua.dressing_input_complete")
      vim.api.nvim_buf_set_option(bufnr, "omnifunc", "")
      vim.api.nvim_buf_set_keymap(
        bufnr,
        "i",
        "<Tab>",
        [[luaeval("require('dressing.input').trigger_completion()")]],
        { expr = true }
      )
    end
    vim.cmd([[
        autocmd BufLeave <buffer> ++nested ++once lua require('dressing.input').confirm()
    ]])
    vim.cmd("startinsert!")
    if opts.default then
      vim.api.nvim_feedkeys(opts.default, "n", false)
    end

    -- Close the completion menu if visible
    if vim.fn.pumvisible() == 1 then
      local escape_key = vim.api.nvim_replace_termcodes("<C-e>", true, false, true)
      vim.api.nvim_feedkeys(escape_key, "n", true)
    end

    M.highlight()
  end,
})

return M
