local M = {}

M.is_supported = function()
  return pcall(require, "telescope")
end

M.select = function(config, items, opts, on_choice)
  local themes = require("telescope.themes")
  local actions = require("telescope.actions")
  local state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  local entry_maker = function(item)
    local formatted = opts.format_item(item)
    return {
      display = formatted,
      ordinal = formatted,
      value = item,
    }
  end

  local picker_opts = themes[string.format("get_%s", config.theme)]({
    previewer = false,
  })
  pickers.new(picker_opts, {
    prompt_title = opts.prompt,
    finder = finders.new_table({
      results = items,
      entry_maker = entry_maker,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = state.get_selected_entry()
        actions._close(prompt_bufnr, false)
        if not selection then
          -- User did not select anything.
          on_choice(nil, nil)
          return
        end
        local idx = nil
        for i, item in ipairs(items) do
          if item == selection.value then
            idx = i
            break
          end
        end
        on_choice(selection.value, idx)
      end)

      actions.close:replace(function()
        actions._close(prompt_bufnr, false)
        on_choice(nil, nil)
      end)

      return true
    end,
  }):find()
end

return M
