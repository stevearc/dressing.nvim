local M = {}

M.create_plug_maps = function(bufnr, plug_bindings)
  for _, binding in ipairs(plug_bindings) do
    vim.keymap.set("", binding.plug, binding.rhs, { buffer = bufnr, desc = binding.desc })
  end
end

---@param bufnr number
---@param mode string
---@param bindings table<string, string>
---@param prefix string
M.create_maps_to_plug = function(bufnr, mode, bindings, prefix)
  local maps
  if mode == "i" then
    maps = vim.api.nvim_buf_get_keymap(bufnr, "")
  end
  for lhs, rhs in pairs(bindings) do
    if rhs then
      -- Prefix with <Plug> unless this is a <Cmd> or :Cmd mapping
      if type(rhs) == "string" and not rhs:match("[<:]") then
        rhs = "<Plug>" .. prefix .. rhs
      end
      if mode == "i" then
        -- HACK for some reason I can't get plug mappings to work in insert mode
        for _, map in ipairs(maps) do
          if map.lhs == rhs then
            rhs = map.callback or map.rhs
            break
          end
        end
      end
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, remap = true })
    end
  end
end

return M
