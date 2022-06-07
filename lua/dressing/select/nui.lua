local M = {}

M.is_supported = function()
  return pcall(require, "nui.menu")
end

M.select = function(config, items, opts, on_choice)
  local Menu = require("nui.menu")
  local event = require("nui.utils.autocmd").event
  local lines = {}
  local line_width = 1
  for i, item in ipairs(items) do
    local line = opts.format_item(item)
    line_width = math.max(line_width, vim.api.nvim_strwidth(line))
    table.insert(lines, Menu.item(line, { value = item, idx = i }))
  end

  if not config.size then
    line_width = math.max(line_width, config.min_width)
    local height = math.max(#lines, config.min_height)
    config.size = {
      width = line_width,
      height = height,
    }
  end

  local border = vim.deepcopy(config.border)
  border.text = {
    top = opts.prompt,
    top_align = "center",
  }
  local menu = Menu({
    position = config.position,
    size = config.size,
    relative = config.relative,
    border = border,
    buf_options = config.buf_options,
    win_options = config.win_options,
    enter = true,
  }, {
    lines = lines,
    max_width = config.max_width,
    max_height = config.max_height,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "<C-c>" },
      submit = { "<CR>" },
    },
    on_close = function()
      on_choice(nil, nil)
    end,
    on_submit = function(item)
      on_choice(item.value, item.idx)
    end,
  })

  menu:mount()

  menu:on(event.BufLeave, menu.menu_props.on_close, { once = true })
end

return M
