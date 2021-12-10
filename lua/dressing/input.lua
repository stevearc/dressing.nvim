local global_config = require("dressing.config")
local util = require("dressing.util")
local M = {}

local context = {
  opts = nil,
  on_confirm = nil,
  winid = nil,
  title_winid = nil,
}

local function close_completion_window()
  if vim.fn.pumvisible() == 1 then
    local escape_key = vim.api.nvim_replace_termcodes("<C-e>", true, false, true)
    vim.api.nvim_feedkeys(escape_key, "n", true)
  end
end

M.confirm = function(text)
  if not context.on_confirm then
    return
  end
  close_completion_window()
  local ctx = context
  context = {}
  vim.cmd("stopinsert")
  -- We have to wait briefly for the popup window to close (if present),
  -- otherwise vim gets into a very weird and bad state. I was seeing text get
  -- deleted from the buffer after the input window closes.
  vim.defer_fn(function()
    if ctx.title_winid then
      pcall(vim.api.nvim_win_close, ctx.title_winid, true)
    end
    pcall(vim.api.nvim_win_close, ctx.winid, true)
    if text == "" then
      text = nil
    end
    -- Defer the callback because we just closed windows and left insert mode.
    -- In practice from my testing, if the user does something right now (like,
    -- say, opening another input modal) it could happen improperly. I was
    -- seeing my successive modals fail to enter insert mode.
    vim.defer_fn(function()
      ctx.on_confirm(text)
    end, 5)
  end, 5)
end

M.confirm_non_prompt = function()
  local text = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]
  M.confirm(text)
end

M.close = function()
  M.confirm()
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
    if global_config.input.prompt_buffer then
      return vim.api.nvim_strwidth(context.opts.prompt)
    else
      return 0
    end
  else
    local completion = context.opts.completion
    local pieces = split(completion, ",")
    if pieces[1] == "custom" or pieces[1] == "customlist" then
      local vimfunc = pieces[2]
      local ret = vim.fn[vimfunc](base, base, vim.fn.strlen(base))
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

    -- Create or update the window
    local prompt = opts.prompt or config.default_prompt
    local width
    if config.prompt_buffer then
      width = util.calculate_width(config.prefer_width + vim.api.nvim_strwidth(prompt), config)
    else
      width = util.calculate_width(config.prefer_width, config)
    end
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
    local winid, bufnr, title_winid
    -- If the input window is already open, hijack it
    if context.winid and vim.api.nvim_win_is_valid(context.winid) then
      winid = context.winid
      -- Make sure the previous on_confirm callback is called with nil
      vim.schedule(context.on_confirm)
      vim.api.nvim_win_set_width(winid, width)
      bufnr = vim.api.nvim_win_get_buf(winid)
      title_winid = context.title_winid
    else
      bufnr = vim.api.nvim_create_buf(false, true)
      winid = vim.api.nvim_open_win(bufnr, true, winopt)
    end
    context = {
      winid = winid,
      title_winid = title_winid,
      on_confirm = on_confirm,
      opts = opts,
    }
    vim.api.nvim_win_set_option(winid, "winblend", config.winblend)

    -- Finish setting up the buffer
    vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(bufnr, "filetype", "DressingInput")
    local keyopts = { silent = true, noremap = true }
    local close_rhs = "<cmd>lua require('dressing.input').close()<CR>"
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", close_rhs, keyopts)
    if config.insert_only then
      vim.api.nvim_buf_set_keymap(bufnr, "i", "<Esc>", close_rhs, keyopts)
    end

    if config.prompt_buffer then
      vim.api.nvim_buf_set_option(bufnr, "buftype", "prompt")
      vim.fn.prompt_setprompt(bufnr, prompt)
      -- Would prefer to use v:lua directly here, but it doesn't work :(
      vim.fn.prompt_setcallback(bufnr, "dressing#prompt_confirm")
      vim.fn.prompt_setinterrupt(bufnr, "dressing#prompt_cancel")
    else
      local confirm_rhs = "<cmd>lua require('dressing.input').confirm_non_prompt()<CR>"
      -- If we're not using the prompt buffer, we need to put the prompt into a
      -- separate title window that will appear in the input window border
      vim.api.nvim_buf_set_keymap(bufnr, "i", "<C-c>", close_rhs, keyopts)
      vim.api.nvim_buf_set_keymap(bufnr, "i", "<CR>", confirm_rhs, keyopts)
      vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", confirm_rhs, keyopts)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, { "" })
      -- Disable nvim-cmp if installed
      local ok, cmp = pcall(require, "cmp")
      if ok then
        cmp.setup.buffer({ enabled = false })
      end
      -- Create the title window once the main window is placed.
      -- Have to defer here or the title will be in the wrong location
      vim.defer_fn(function()
        local titlebuf
        local trimmed_prompt = string.gsub(prompt, "^%s*(.-)%s*$", "%1")
        local prompt_width = math.min(width, 2 + vim.api.nvim_strwidth(trimmed_prompt))
        if context.title_winid and vim.api.nvim_win_is_valid(context.title_winid) then
          title_winid = context.title_winid
          titlebuf = vim.api.nvim_win_get_buf(title_winid)
          vim.api.nvim_win_set_width(title_winid, prompt_width)
        else
          titlebuf = vim.api.nvim_create_buf(false, true)
          title_winid = vim.api.nvim_open_win(titlebuf, false, {
            relative = "win",
            win = winid,
            width = prompt_width,
            height = 1,
            row = -1,
            col = 1,
            focusable = false,
            zindex = 151,
            style = "minimal",
            noautocmd = true,
          })
        end
        if winid == context.winid then
          context.title_winid = title_winid
        end
        vim.api.nvim_win_set_option(title_winid, "winblend", config.winblend)
        vim.api.nvim_buf_set_lines(titlebuf, 0, -1, true, { " " .. trimmed_prompt })
        vim.api.nvim_buf_set_option(titlebuf, "bufhidden", "wipe")
      end, 5)
    end

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
        autocmd BufLeave <buffer> ++nested ++once lua require('dressing.input').close()
    ]])

    vim.cmd("startinsert!")
    if opts.default then
      vim.api.nvim_feedkeys(opts.default, "n", false)
    end

    close_completion_window()
    M.highlight()
  end,
})

return M
