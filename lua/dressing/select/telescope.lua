local M = {}

M.is_supported = function()
  return pcall(require, "telescope")
end

M.custom_kind = {
  codeaction = function(opts, defaults, items)
    local entry_display = require("telescope.pickers.entry_display")
    local finders = require("telescope.finders")
    local displayer

    local function make_display(entry)
      local columns = {
        { entry.idx .. ":", "TelescopePromptPrefix" },
        entry.text,
        { entry.client_name, "Comment" },
      }
      return displayer(columns)
    end

    local entries = {}
    local client_width = 1
    local text_width = 1
    local idx_width = 1
    for idx, item in ipairs(items) do
      local client_id = item[1]
      local client_name = vim.lsp.get_client_by_id(client_id).name
      local text = opts.format_item(item)

      client_width = math.max(client_width, vim.api.nvim_strwidth(client_name))
      text_width = math.max(text_width, vim.api.nvim_strwidth(text))
      idx_width = math.max(idx_width, vim.api.nvim_strwidth(tostring(idx)))

      table.insert(entries, {
        idx = idx,
        display = make_display,
        text = text,
        client_name = client_name,
        ordinal = idx .. " " .. text .. " " .. client_name,
        value = item,
      })
    end
    displayer = entry_display.create({
      separator = " ",
      items = {
        { width = idx_width + 1 },
        { width = text_width },
        { width = client_width },
      },
    })

    defaults.finder = finders.new_table({
      results = entries,
      entry_maker = function(item)
        return item
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

  -- schedule_wrap because closing the windows is deferred
  -- See https://github.com/nvim-telescope/telescope.nvim/pull/2336
  -- And we only want to dispatch the callback when we're back in the original win
  on_choice = vim.schedule_wrap(on_choice)

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
