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

  local picker_opts = config

  -- Default to the dropdown theme if no options supplied
  if picker_opts == nil then
    picker_opts = themes.get_dropdown()
  end

  local defaults = {
    prompt_title = opts.prompt,
    previewer = false,
    finder = finders.new_table({
      results = items,
      entry_maker = entry_maker,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = state.get_selected_entry()
        local callback = on_choice
        -- Replace on_choice with a no-op so closing doesn't trigger it
        on_choice = function(_, _) end
        actions.close(prompt_bufnr)
        if not selection then
          -- User did not select anything.
          callback(nil, nil)
          return
        end
        local idx = nil
        for i, item in ipairs(items) do
          if item == selection.value then
            idx = i
            break
          end
        end
        callback(selection.value, idx)
      end)

      actions.close:enhance({
        post = function()
          on_choice(nil, nil)
        end,
      })

      return true
    end,
  }

  -- Hook to allow the caller of vim.ui.select to customize the telescope opts
  if opts.telescope then
    pickers.new(opts.telescope, defaults):find()
  else
    pickers.new(picker_opts, defaults):find()
  end
end

return M
