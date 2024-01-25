local M = {}

M.is_supported = function()
  return pcall(require, "fzf-lua.providers.ui_select")
end

M.select = function(config, items, opts, on_choice)
  local ui_select = require("fzf-lua.providers.ui_select")
  if config and not vim.tbl_isempty(config) then
    -- Registering then unregistering sets the config options
    ui_select.register(config, true)
    ui_select.deregister(nil, true, true)
  end
  -- Defer the callback to allow the mode to fully switch back to normal after the fzf terminal
  local deferred_on_choice = function(...)
    local cb = on_choice
    on_choice = function() end
    local args = vim.F.pack_len(...)
    vim.defer_fn(function()
      cb(vim.F.unpack_len(args))
    end, 10)
  end
  ui_select.ui_select(items, opts, deferred_on_choice)

  -- Because fzf-lua doesn't call the on_choice function if exited (e.g. with <C-c>), we need to
  -- add an autocmd ourselves to make sure that happens.
  vim.api.nvim_create_autocmd("BufUnload", {
    buffer = vim.api.nvim_get_current_buf(),
    once = true,
    nested = true,
    callback = function()
      vim.defer_fn(function()
        local cb = on_choice
        on_choice = function() end
        cb()
      end, 10)
    end,
  })
end

return M
