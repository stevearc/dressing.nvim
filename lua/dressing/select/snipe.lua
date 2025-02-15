local M = {}

local snipe = require("snipe")

M.is_supported = function()
  return pcall(require, "snipe")
end

M._init_snipe_menu = function(config, on_choice)
  config = config or {}

  local default_opts = {
    default_keymaps = {
      auto_setup = true,
    },
  }

  local opts = vim.tbl_deep_extend("keep", default_opts, config.options or {})

  local snipe_menu = require("snipe.menu"):new(opts)

  -- Run user callback if provided
  if config.add_new_buffer_callback then
    snipe_menu:add_new_buffer_callback(function(m)
      config.add_new_buffer_callback(m, on_choice)
    end)
  end

  snipe.ui_select_menu = snipe_menu
end

M.select = function(config, items, opts, on_choice)
  -- Ensure the snipe menu is initialized
  -- It is enough to initialize once
  if not snipe.ui_select_menu then
    M._init_snipe_menu(config, on_choice)
  end

  snipe.ui_select(items, opts, on_choice)
  snipe.ui_select_menu.page = 1
  -- Set cursor to the first item
  vim.api.nvim_win_set_cursor(snipe.ui_select_menu.win, { 1, 0 })

  vim.api.nvim_create_autocmd("BufLeave", {
    desc = "Cancel vim.ui.select",
    once = true,
    callback = function()
      on_choice(nil, nil)
      snipe.ui_select_menu:close()
      -- Reset the title to avoid the title being set for the next menu
      snipe.ui_select_menu.config.open_win_override.title = nil
    end,
  })
end

return M
