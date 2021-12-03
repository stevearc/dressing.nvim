local M = {}

M.is_supported = function()
  return pcall(require, "nui.menu")
end

M.select = function(config, items, opts, on_choice)
  local Menu = require("nui.menu")
  local event = require("nui.utils.autocmd").event
  local lines = {}
  for i, item in ipairs(items) do
    table.insert(lines, Menu.item(opts.format_item(item), { value = item, idx = i }))
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
    buf_options = {
      swapfile = false,
    },
    win_options = {
      winblend = 10,
    },
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
