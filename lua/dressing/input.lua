local global_config = require("dressing.config")
local util = require("dressing.util")
local M = {}

local context = {
  opts = nil,
  on_confirm = nil,
  winid = nil,
  history_idx = nil,
  history_tip = nil,
  start_in_insert = nil,
}

local function set_input(text)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { text })
  vim.api.nvim_win_set_cursor(0, { 1, vim.api.nvim_strwidth(text) })
end
local history = {}
M.history_prev = function()
  if context.history_idx == nil then
    if #history == 0 then
      return
    end
    context.history_tip = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]
    context.history_idx = #history
  elseif context.history_idx == 1 then
    return
  else
    context.history_idx = context.history_idx - 1
  end
  set_input(history[context.history_idx])
end
M.history_next = function()
  if not context.history_idx then
    return
  elseif context.history_idx == #history then
    context.history_idx = nil
    set_input(context.history_tip)
  else
    context.history_idx = context.history_idx + 1
    set_input(history[context.history_idx])
  end
end

local function close_completion_window()
  if vim.fn.pumvisible() == 1 then
    local escape_key = vim.api.nvim_replace_termcodes("<C-e>", true, false, true)
    vim.api.nvim_feedkeys(escape_key, "n", true)
  end
end

local function confirm(text)
  if not context.on_confirm then
    return
  end
  close_completion_window()
  local ctx = context
  context = {}
  if not ctx.start_in_insert then
    vim.cmd("stopinsert")
  end
  -- We have to wait briefly for the popup window to close (if present),
  -- otherwise vim gets into a very weird and bad state. I was seeing text get
  -- deleted from the buffer after the input window closes.
  vim.defer_fn(function()
    pcall(vim.api.nvim_win_close, ctx.winid, true)
    if text == "" then
      text = nil
    end
    if text and history[#history] ~= text then
      table.insert(history, text)
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

M.confirm = function()
  local text = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]
  confirm(text)
end

M.close = function()
  confirm()
end

M.highlight = function()
  if not context.opts then
    return
  end
  local bufnr = vim.api.nvim_win_get_buf(context.winid)
  local opts = context.opts
  local text = vim.api.nvim_buf_get_lines(bufnr, 0, 1, true)[1]
  local ns = vim.api.nvim_create_namespace("DressingHighlight")
  local highlights
  if not opts.highlight then
    highlights = { { 0, -1, "DressingInputText" } }
  elseif type(opts.highlight) == "function" then
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
    return 0
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

local function create_or_update_win(config, prompt, opts)
  local parent_win = 0
  local winopt
  local win_conf
  -- If the previous window is still open and valid, we're going to update it
  if context.winid and vim.api.nvim_win_is_valid(context.winid) then
    win_conf = vim.api.nvim_win_get_config(context.winid)
    parent_win = win_conf.win
    winopt = {
      relative = win_conf.relative,
      win = win_conf.win,
    }
  else
    winopt = {
      relative = config.relative,
      anchor = config.anchor,
      border = config.border,
      height = 1,
      style = "minimal",
      noautocmd = true,
    }
  end
  -- First calculate the desired base width of the modal
  local prefer_width = util.calculate_width(
    config.relative,
    config.prefer_width,
    config,
    parent_win
  )
  -- Then expand the width to fit the prompt and default value
  prefer_width = math.max(prefer_width, 4 + vim.api.nvim_strwidth(prompt))
  if opts.default then
    prefer_width = math.max(prefer_width, 2 + vim.api.nvim_strwidth(opts.default))
  end
  -- Then recalculate to clamp final value to min/max
  local width = util.calculate_width(config.relative, prefer_width, config, parent_win)
  winopt.row = util.calculate_row(config.relative, 1, parent_win)
  winopt.col = util.calculate_col(config.relative, width, parent_win)
  winopt.width = width

  if win_conf and config.relative == "cursor" then
    -- If we're cursor-relative we should actually not adjust the row/col to
    -- prevent jumping. Also remove related args.
    if config.relative == "cursor" then
      winopt.row = nil
      winopt.col = nil
      winopt.relative = nil
      winopt.win = nil
    end
  end

  winopt = config.override(winopt) or winopt

  -- If the floating win was already open
  if win_conf then
    -- Make sure the previous on_confirm callback is called with nil
    vim.schedule(context.on_confirm)
    vim.api.nvim_win_set_config(context.winid, winopt)
    local start_in_insert = context.start_in_insert
    return context.winid, start_in_insert
  else
    local start_in_insert = string.sub(vim.api.nvim_get_mode().mode, 1, 1) == "i"
    local bufnr = vim.api.nvim_create_buf(false, true)
    local winid = vim.api.nvim_open_win(bufnr, true, winopt)
    return winid, start_in_insert
  end
end

setmetatable(M, {
  -- use schedule_wrap to avoid a bug when vim opens
  -- (see https://github.com/stevearc/dressing.nvim/issues/15)
  __call = vim.schedule_wrap(function(_, opts, on_confirm)
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

    local winid, start_in_insert = create_or_update_win(config, prompt, opts)
    context = {
      winid = winid,
      on_confirm = on_confirm,
      opts = opts,
      history_idx = nil,
      start_in_insert = start_in_insert,
    }
    vim.api.nvim_win_set_option(winid, "winblend", config.winblend)
    vim.api.nvim_win_set_option(winid, "winhighlight", config.winhighlight)
    local bufnr = vim.api.nvim_win_get_buf(winid)

    -- Finish setting up the buffer
    vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
    local keyopts = { silent = true, noremap = true }
    local close_rhs = "<cmd>lua require('dressing.input').close()<CR>"
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", close_rhs, keyopts)
    if config.insert_only then
      vim.api.nvim_buf_set_keymap(bufnr, "i", "<Esc>", close_rhs, keyopts)
    end

    local confirm_rhs = "<cmd>lua require('dressing.input').confirm()<CR>"
    vim.api.nvim_buf_set_keymap(bufnr, "i", "<C-c>", close_rhs, keyopts)
    vim.api.nvim_buf_set_keymap(bufnr, "i", "<CR>", confirm_rhs, keyopts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", confirm_rhs, keyopts)
    vim.api.nvim_buf_set_keymap(
      bufnr,
      "i",
      "<Up>",
      "<cmd>lua require('dressing.input').history_prev()<CR>",
      keyopts
    )
    vim.api.nvim_buf_set_keymap(
      bufnr,
      "i",
      "<Down>",
      "<cmd>lua require('dressing.input').history_next()<CR>",
      keyopts
    )
    vim.api.nvim_buf_set_option(bufnr, "filetype", "DressingInput")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, { opts.default or "" })
    -- Disable nvim-cmp if installed
    local ok, cmp = pcall(require, "cmp")
    if ok then
      cmp.setup.buffer({ enabled = false })
    end
    util.add_title_to_win(winid, string.gsub(prompt, "^%s*(.-)%s*$", "%1"), { align = "left" })

    vim.cmd([[
      aug DressingHighlight
        autocmd! * <buffer>
        autocmd TextChanged <buffer> lua require('dressing.input').highlight()
        autocmd TextChangedI <buffer> lua require('dressing.input').highlight()
      aug END
    ]])

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
      aug DressingCloseWin
        autocmd! * <buffer>
        autocmd BufLeave <buffer> ++nested ++once lua require('dressing.input').close()
      aug END
    ]])

    vim.cmd("startinsert!")
    close_completion_window()
    M.highlight()
  end),
})

return M
