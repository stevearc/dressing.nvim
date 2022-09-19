local M = {}

M.is_supported = function()
  return pcall(require, "fzf-lua")
end

M.select = function(config, items, opts, on_choice)
  local fzf = require("fzf-lua.core")
  local labels = {}
  for i, item in ipairs(items) do
    table.insert(labels, string.format("%d: %s", i, opts.format_item(item)))
  end

  local fzf_opts = vim.tbl_deep_extend("keep", config, {
    fzf_opts = {
      ["--no-multi"] = "",
      ["--preview-window"] = "hidden:right:0",
    },
  })
  fzf.fzf_wrap(fzf_opts, labels, function(selected)
    if not selected then
      on_choice(nil, nil)
    else
      local label = selected[1]
      local colon = string.find(label, ":")
      local lnum = tonumber(string.sub(label, 1, colon - 1))
      local item = items[lnum]
      on_choice(item, lnum)
    end
  end)()
end

return M
