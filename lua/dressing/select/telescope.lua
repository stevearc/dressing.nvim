local M = {}

M.is_supported = function()
  return pcall(require, "telescope")
end

M.custom_kind = {
  codeaction = function(opts, defaults, items)
    local entry_display = require("telescope.pickers.entry_display")
    local finders = require("telescope.finders")
    local displayer = entry_display.create({
      separator = " ",
      items = {
        { remaining = true },
        { width = 16 },
      },
    })

    local function make_display(entry)
      local client_name = vim.lsp.get_client_by_id(entry.client_id).name
      local columns = {
        opts.format_item(entry.value),
        { client_name, "Comment" },
      }
      return displayer(columns)
    end
    defaults.finder = finders.new_table({
      results = items,
      entry_maker = function(item)
        return {
          display = make_display,
          client_id = item[1],
          ordinal = opts.format_item(item),
          value = item,
        }
      end,
    })
  end,
}

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

  if M.custom_kind[opts.kind] then
    M.custom_kind[opts.kind](opts, defaults, items)
  end

  -- Hook to allow the caller of vim.ui.select to customize the telescope opts
  if opts.telescope then
    pickers.new(opts.telescope, defaults):find()
  else
    pickers.new(picker_opts, defaults):find()
  end
end

return M
