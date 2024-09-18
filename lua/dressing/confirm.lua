local global_config = require("dressing.config")
local patch = require("dressing.patch")
local util = require("dressing.util")

return function(message, opts, callback)
  local config = global_config.get_mod_config("confirm", message, opts)
  if not config.enabled then
    return patch.original_mods.confirm(opts, callback)
  end
  vim.validate({
    message = { message, "s" },
    opts = { opts, "t" },
    callback = { callback, "f" },
  })
  vim.validate({
    choices = { opts.choices, "t", true },
    default = { opts.default, "n", true },
    type = { opts.type, "s", true },
  })
  vim.api.nvim_set_hl(0, "ConfirmCursor", { blend = 100, default = true })
  if not opts.choices or vim.tbl_isempty(opts.choices) then
    opts.choices = { "&OK" }
  end
  if not opts.default then
    opts.default = 1
  end
  -- TODO this doesn't do anything yet
  if not opts.type then
    opts.type = "G"
  else
    opts.type = string.sub(opts.type, 1, 1)
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  local winid

  local guicursor = vim.o.guicursor
  local function choose(idx)
    local cb = callback
    callback = function(_) end
    if winid then
      vim.api.nvim_win_close(winid, true)
    end
    vim.o.guicursor = guicursor
    local choice = opts.choices[idx]
    if choice then
      choice = choice:gsub("&", "")
    end
    cb(idx, choice)
  end
  local function cancel()
    choose(0)
  end

  local clean_choices = {}
  local choice_shortcut_idx = {}
  for i, choice in ipairs(opts.choices) do
    local idx = choice:find("&")
    local key
    if idx and idx < string.len(choice) then
      table.insert(clean_choices, choice:sub(1, idx - 1) .. choice:sub(idx + 1))
      key = choice:sub(idx + 1, idx + 1)
      table.insert(choice_shortcut_idx, idx)
    else
      key = choice:sub(1, 1)
      table.insert(clean_choices, choice)
      table.insert(choice_shortcut_idx, 1)
    end
    vim.keymap.set("n", key:lower(), function()
      choose(i)
    end, { buffer = bufnr })
    vim.keymap.set("n", key:upper(), function()
      choose(i)
    end, { buffer = bufnr })
  end
  vim.keymap.set("n", "<C-c>", cancel, { buffer = bufnr })
  vim.keymap.set("n", "<Esc>", cancel, { buffer = bufnr })

  local lines = vim.split(message, "\n")
  local highlights = {}
  table.insert(lines, "")

  -- Calculate the width of the choices if they are on a single line
  local choices_width = 0
  for _, choice in ipairs(clean_choices) do
    choices_width = choices_width + vim.api.nvim_strwidth(choice)
  end
  -- Make sure to account for spacing
  choices_width = choices_width + #clean_choices - 1

  local desired_width = choices_width
  for _, line in ipairs(lines) do
    local len = string.len(line)
    if len > desired_width then
      desired_width = len
    end
  end

  local width = util.calculate_width("editor", desired_width, config)

  if width < choices_width then
    -- Render one choice per line
    for i, choice in ipairs(clean_choices) do
      table.insert(lines, choice)
      table.insert(highlights, { "Keyword", #lines, choice_shortcut_idx[i] - 1 })
    end
  else
    -- Render all choices on a single line
    local extra_spacing = width - choices_width
    local line = ""
    local num_dividers = #clean_choices - 1
    for i, choice in ipairs(clean_choices) do
      if i > 1 then
        line = line .. " " .. string.rep(" ", math.floor(extra_spacing / num_dividers))
        if extra_spacing % num_dividers >= i then
          line = line .. " "
        end
      end
      local col_start = line:len() - 1
      line = line .. choice
      table.insert(highlights, { "Keyword", #lines + 1, col_start + choice_shortcut_idx[i] })
    end
    table.insert(lines, line)
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
  local ns = vim.api.nvim_create_namespace("confirm")
  for _, hl in ipairs(highlights) do
    local group, lnum, col_start, col_end = unpack(hl)
    if not col_end then
      col_end = col_start + 1
    end
    vim.api.nvim_buf_add_highlight(bufnr, ns, group, lnum - 1, col_start, col_end)
  end

  local height = util.calculate_height("editor", #lines, config)
  local winopt = {
    relative = "editor",
    border = config.border,
    zindex = config.zindex,
    style = "minimal",
    width = width,
    height = height,
    col = math.floor((util.get_editor_width() - width) / 2),
    row = math.floor((util.get_editor_height() - height) / 2),
  }
  if vim.fn.has("nvim-0.9") == 1 and config.title ~= "" then
    winopt.title = config.title
    winopt.title_pos = config.title_pos
  end
  winopt = config.override(winopt) or winopt
  winid = vim.api.nvim_open_win(bufnr, true, winopt)
  for k, v in pairs(config.buf_options) do
    vim.api.nvim_buf_set_option(bufnr, k, v)
  end
  for k, v in pairs(config.win_options) do
    vim.api.nvim_win_set_option(winid, k, v)
  end
  vim.o.guicursor = "a:ConfirmCursor"

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = bufnr,
    callback = cancel,
    once = true,
    nested = true,
  })
  vim.api.nvim_create_autocmd("WinLeave", {
    callback = cancel,
    once = true,
    nested = true,
  })
  vim.bo[bufnr].modifiable = false
end
