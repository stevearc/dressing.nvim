local global_config = require("dressing.config")
local map_util = require("dressing.map_util")
local patch = require("dressing.patch")
local util = require("dressing.util")
local M = {}

---@class (exact) dressing.InputContext
---@field opts? dressing.InputOptions
---@field on_confirm? fun(text?: string)
---@field winid? integer
---@field history_idx? integer
---@field history_tip? string
---@field start_in_insert? boolean

---@class (exact) dressing.InputOptions
---@field prompt? string
---@field default? string
---@field completion? string
---@field highlight? string|fun(text: string): any[][]
---@field cancelreturn? string

---@type dressing.InputContext
local context = {
  opts = nil,
  on_confirm = nil,
  winid = nil,
  history_idx = nil,
  history_tip = nil,
  start_in_insert = nil,
}

local keymaps = {
  {
    desc = "Close vim.ui.input without a result",
    plug = "<Plug>DressingInput:Close",
    rhs = function()
      M.close()
    end,
  },
  {
    desc = "Close vim.ui.input with the current buffer contents",
    plug = "<Plug>DressingInput:Confirm",
    rhs = function()
      M.confirm()
    end,
  },
  {
    desc = "Show previous vim.ui.input history entry",
    plug = "<Plug>DressingInput:HistoryPrev",
    rhs = function()
      M.history_prev()
    end,
  },
  {
    desc = "Show next vim.ui.input history entry",
    plug = "<Plug>DressingInput:HistoryNext",
    rhs = function()
      M.history_next()
    end,
  },
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
    local ok, err = pcall(vim.api.nvim_win_close, ctx.winid, true)
    -- If we couldn't close the window because we're in the cmdline,
    -- try again after WinLeave
    if not ok and err and err:match("^E11:") then
      local winid = ctx.winid
      vim.api.nvim_create_autocmd("WinLeave", {
        callback = vim.schedule_wrap(function()
          pcall(vim.api.nvim_win_close, winid, true)
        end),
        once = true,
      })
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
  confirm(context.opts and context.opts.cancelreturn)
end

---Ensure that the input only has a single line
local function remove_extra_lines()
  local winid = context.winid
  if not winid or not vim.api.nvim_win_is_valid(winid) then
    return
  end
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
  if #lines == 1 then
    return
  end
  while #lines > 1 do
    if lines[1]:match("^%s*$") then
      table.remove(lines, 1)
    else
      table.remove(lines)
    end
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
end

local function apply_highlight()
  local opts = context.opts
  if not opts then
    return
  end
  local bufnr = vim.api.nvim_win_get_buf(context.winid)
  local text = vim.api.nvim_buf_get_lines(bufnr, 0, 1, true)[1]
  local ns = vim.api.nvim_create_namespace("DressingHighlight")
  local highlights = {}
  if type(opts.highlight) == "function" then
    highlights = opts.highlight(text)
  elseif opts.highlight then
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

M.completefunc = function(findstart, base)
  local completion = context.opts and context.opts.completion
  if not completion then
    return findstart == 1 and 0 or {}
  end
  if findstart == 1 then
    return 0
  else
    local pieces = vim.split(completion, ",", { plain = true })
    if pieces[1] == "custom" or pieces[1] == "customlist" then
      local vimfunc = pieces[2]
      local ret
      if vim.startswith(vimfunc, "v:lua.") then
        local load_func = string.format("return %s(...)", vimfunc:sub(7))
        local luafunc, err = loadstring(load_func)
        if not luafunc then
          vim.api.nvim_err_writeln(
            string.format("Could not find completion function %s: %s", vimfunc, err)
          )
          return {}
        end
        ret = luafunc(base, base, vim.fn.strlen(base))
      else
        ret = vim.fn[vimfunc](base, base, vim.fn.strlen(base))
      end
      if pieces[1] == "custom" then
        ret = vim.split(ret, "\n", { plain = true })
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

M.trigger_completion = function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  else
    return "<C-x><C-u>"
  end
end

---@param lines string[]
---@return integer
local function get_max_strwidth(lines)
  local max = 0
  for _, line in ipairs(lines) do
    max = math.max(max, vim.api.nvim_strwidth(line))
  end
  return max
end

---@param config table
---@param prompt_lines string[]
---@param default? string
---@return integer
---@return boolean
local function create_or_update_win(config, prompt_lines, default)
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
      anchor = "SW",
      border = config.border,
      height = 1,
      style = "minimal",
      noautocmd = true,
    }
  end

  -- First calculate the desired base width of the modal
  local prefer_width =
    util.calculate_width(config.relative, config.prefer_width, config, parent_win)
  -- Then expand the width to fit the prompt and default value
  prefer_width = math.max(prefer_width, 4 + get_max_strwidth(prompt_lines))
  if default then
    prefer_width = math.max(prefer_width, 2 + vim.api.nvim_strwidth(default))
  end
  -- Then recalculate to clamp final value to min/max
  local width = util.calculate_width(config.relative, prefer_width, config, parent_win)
  winopt.row = util.calculate_row(config.relative, 1, parent_win)
  if #prompt_lines > 1 then
    -- If we're going to add a multiline prompt window, adjust the positioning down to make room
    winopt.row = winopt.row + #prompt_lines
  end
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
  if vim.fn.has("nvim-0.9") == 1 and #prompt_lines == 1 then
    winopt.title = prompt_lines[1]:gsub("^%s*(.-)%s*$", " %1 ")
    -- We used to use "prompt_align" here
    winopt.title_pos = config.prompt_align or config.title_pos
  end

  winopt = config.override(winopt) or winopt

  local winid, start_in_insert
  -- If the floating win was already open
  if win_conf then
    -- Make sure the previous on_confirm callback is called with nil
    vim.schedule(context.on_confirm)
    vim.api.nvim_win_set_config(context.winid, winopt)
    winid = context.winid
    start_in_insert = context.start_in_insert
  else
    start_in_insert = string.sub(vim.api.nvim_get_mode().mode, 1, 1) == "i"
    local bufnr = vim.api.nvim_create_buf(false, true)
    winid = vim.api.nvim_open_win(bufnr, true, winopt)
  end

  -- If the prompt is multiple lines, create another window for it
  local prev_prompt_win = vim.w[winid].prompt_win
  if prev_prompt_win and vim.api.nvim_win_is_valid(prev_prompt_win) then
    vim.api.nvim_win_close(prev_prompt_win, true)
  end
  if #prompt_lines > 1 then
    -- HACK to force the parent window to position itself
    -- See https://github.com/neovim/neovim/issues/13403
    vim.cmd("redraw")
    local prompt_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[prompt_buf].swapfile = false
    vim.bo[prompt_buf].bufhidden = "wipe"
    local row = -1 * #prompt_lines
    local col = 0
    if winopt.border then
      row = row - 2
      col = col - 1
    end
    local prompt_win = vim.api.nvim_open_win(prompt_buf, false, {
      relative = "win",
      win = winid,
      width = winopt.width,
      height = #prompt_lines,
      row = row,
      col = col,
      focusable = false,
      zindex = (winopt.zindex or 50) - 1,
      style = "minimal",
      border = winopt.border,
      noautocmd = true,
    })
    for option, value in pairs(config.win_options) do
      vim.api.nvim_set_option_value(option, value, { scope = "local", win = prompt_win })
    end
    vim.api.nvim_buf_set_lines(prompt_buf, 0, -1, true, prompt_lines)
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(winid),
      once = true,
      nested = true,
      callback = function()
        vim.api.nvim_win_close(prompt_win, true)
      end,
    })
    vim.w[winid].prompt_win = prompt_win
  end

  ---@cast winid integer
  ---@cast start_in_insert boolean
  return winid, start_in_insert
end

---@param opts string|dressing.InputOptions
---@param on_confirm fun(text?: string)
local function show_input(opts, on_confirm)
  vim.validate({
    on_confirm = { on_confirm, "function", false },
  })
  opts = opts or {}
  if type(opts) ~= "table" then
    opts = { prompt = tostring(opts) }
  end
  local config = global_config.get_mod_config("input", opts)
  if not config.enabled then
    return patch.original_mods.input(opts, on_confirm)
  end
  if vim.fn.hlID("DressingInputText") ~= 0 then
    vim.notify(
      'DressingInputText highlight group is deprecated. Set winhighlight="NormalFloat:MyHighlightGroup" instead',
      vim.log.levels.WARN
    )
  end

  local prompt = opts.prompt or config.default_prompt
  local prompt_lines = vim.split(prompt, "\n", { plain = true, trimempty = true })

  -- Create or update the window
  local winid, start_in_insert = create_or_update_win(config, prompt_lines, opts.default)
  context = {
    winid = winid,
    on_confirm = on_confirm,
    opts = opts,
    history_idx = nil,
    start_in_insert = start_in_insert,
  }
  for option, value in pairs(config.win_options) do
    vim.api.nvim_set_option_value(option, value, { scope = "local", win = winid })
  end
  local bufnr = vim.api.nvim_win_get_buf(winid)

  -- Finish setting up the buffer
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].bufhidden = "wipe"
  for k, v in pairs(config.buf_options) do
    vim.bo[bufnr][k] = v
  end

  map_util.create_plug_maps(bufnr, keymaps)
  for mode, user_maps in pairs(config.mappings) do
    map_util.create_maps_to_plug(bufnr, mode, user_maps, "DressingInput:")
  end

  if config.insert_only then
    vim.keymap.set("i", "<Esc>", M.close, { buffer = bufnr })
  end

  vim.bo[bufnr].filetype = "DressingInput"
  local default = string.gsub(opts.default or "", "\n", " ")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, { default })
  if vim.fn.has("nvim-0.9") == 0 and #prompt_lines == 1 then
    util.add_title_to_win(
      winid,
      string.gsub(prompt_lines[1], "^%s*(.-)%s*$", "%1"),
      { align = config.prompt_align }
    )
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    desc = "Update highlights",
    buffer = bufnr,
    callback = function()
      remove_extra_lines()
      apply_highlight()
    end,
  })

  -- Configure nvim-cmp if installed
  local has_cmp, cmp = pcall(require, "cmp")
  if has_cmp then
    cmp.setup.buffer({
      enabled = opts.completion ~= nil,
      sources = {
        { name = "omni" },
      },
    })
  end
  -- Disable mini.nvim completion if installed
  vim.api.nvim_buf_set_var(bufnr, "minicompletion_disable", true)
  if opts.completion then
    vim.bo[bufnr].completefunc = "v:lua.require'dressing.input'.completefunc"
    vim.bo[bufnr].omnifunc = "v:lua.require'dressing.input'.completefunc"
    -- Only set up <Tab> user completion if cmp is not active
    if not has_cmp or not pcall(require, "cmp_omni") then
      vim.keymap.set("i", "<Tab>", M.trigger_completion, { buffer = bufnr, expr = true })
    end
  end

  vim.api.nvim_create_autocmd("BufLeave", {
    desc = "Cancel vim.ui.input",
    buffer = bufnr,
    nested = true,
    once = true,
    callback = M.close,
  })

  if config.start_in_insert then
    vim.cmd("startinsert!")
  end
  close_completion_window()
  apply_highlight()
end

setmetatable(M, {
  -- use schedule_wrap to avoid a bug when vim opens
  -- (see https://github.com/stevearc/dressing.nvim/issues/15)
  __call = util.schedule_wrap_before_vimenter(function(_, opts, on_confirm)
    show_input(opts, on_confirm)
  end),
})

return M
