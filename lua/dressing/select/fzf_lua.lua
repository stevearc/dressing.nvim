local M = {}

M.is_supported = function()
  return pcall(require, "fzf-lua")
end

M.select = function(config, items, opts, on_choice)
  local fzf = require("fzf-lua")
  local labels = {}
  for i, item in ipairs(items) do
    table.insert(labels, string.format("%d: %s", i, opts.format_item(item)))
  end

  local prompt = (opts.prompt or "Select one of") .. "> "

  local fzf_opts = vim.tbl_deep_extend("keep", config, {
    prompt = prompt,
    fzf_opts = {
      ["--no-multi"] = "",
      ["--preview-window"] = "hidden:right:0",
    },
    actions = {
      -- "default" gets called when pressing "enter"
      -- all fzf style binds (i.e. "ctrl-y") are valid
      ["default"] = function(selected, _)
        if not selected then
          on_choice(nil, nil)
        else
          local label = selected[1]
          local lnum = tonumber(label:match("^(%d+):"))
          local item = items[lnum]
          on_choice(item, lnum)
        end
      end,
    },
  })
  fzf.fzf_exec(labels, fzf_opts)
end

return M
