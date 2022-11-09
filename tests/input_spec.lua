require("plenary.async").tests.add_to_env()
local dressing = require("dressing")
local util = require("tests.util")
local channel = a.control.channel

local function run_input(keys, opts)
  opts = opts or {}
  local tx, rx = channel.oneshot()
  vim.ui.input(opts, tx)
  util.feedkeys(vim.list_extend(
    { "i" }, -- HACK have to do this because :startinsert doesn't work in tests,
    keys
  ))
  if opts.after_fn then
    opts.after_fn()
  end
  return rx()
end

a.describe("input modal", function()
  before_each(function()
    dressing.patch()
    dressing.setup()
  end)

  after_each(function()
    -- Clean up all floating windows so one test failure doesn't cascade
    for _, winid in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(winid).relative ~= "" then
        vim.api.nvim_win_close(winid, true)
      end
    end
  end)

  a.it("accepts input", function()
    local ret = run_input({
      "my text",
      "<CR>",
    })
    assert(ret == "my text", string.format("Got '%s' expected 'my text'", ret))
  end)

  a.it("Cancels input on <C-c>", function()
    local ret = run_input({
      "my text",
      "<C-c>",
    })
    assert(ret == nil, string.format("Got '%s' expected nil", ret))
  end)

  a.it("cancels input when leaving the window", function()
    local ret = run_input({
      "my text",
    }, {
      after_fn = function()
        vim.cmd([[wincmd p]])
      end,
    })
    assert(ret == nil, string.format("Got '%s' expected nil", ret))
  end)

  a.it("cancels on <Esc> when insert_only = true", function()
    require("dressing.config").input.insert_only = true
    local ret = run_input({
      "my text",
      "<Esc>",
    })
    assert(ret == nil, string.format("Got '%s' expected nil", ret))
  end)

  a.it("does not cancel on <Esc> when insert_only = false", function()
    require("dressing.config").input.insert_only = false
    local ret = run_input({
      "my text",
      "<Esc>",
      "<CR>",
    })
    assert(ret == "my text", string.format("Got '%s' expected 'my text'", ret))
  end)

  a.it("returns cancelreturn when input is canceled <C-c>", function()
    local ret = run_input({
      "my text",
      "<C-c>",
    }, { cancelreturn = "CANCELED" })
    assert(ret == "CANCELED", string.format("Got '%s' expected nil", ret))
  end)

  a.it("returns empty string when input is empty", function()
    local ret = run_input({
      "<CR>",
    })
    assert(ret == "", string.format("Got '%s' expected nil", ret))
  end)

  a.it("returns empty string when input is empty, even if cancelreturn set", function()
    local ret = run_input({
      "<CR>",
    }, { cancelreturn = "CANCELED" })
    assert(ret == "", string.format("Got '%s' expected nil", ret))
  end)

  a.it("starts in normal mode when start_in_insert = false", function()
    local orig_cmd = vim.cmd
    local startinsert_called = false
    vim.cmd = function(cmd)
      if cmd == "startinsert!" then
        startinsert_called = true
      end
      orig_cmd(cmd)
    end

    require("dressing.config").input.start_in_insert = false
    run_input({
      "my text",
      "<CR>",
    }, {
      after_fn = function()
        vim.cmd = orig_cmd
      end,
    })
    assert(not startinsert_called, "Got 'true' expected 'false'")
  end)

  a.it("cancels first callback if second input is opened", function()
    local tx, rx = channel.oneshot()
    vim.ui.input({}, tx)
    util.feedkeys({
      "i", -- HACK have to do this because :startinsert doesn't work in tests,
      "my text",
    })
    vim.ui.input({}, function() end)
    local ret = rx()
    assert(ret == nil, string.format("Got '%s' expected nil", ret))
  end)

  a.it("supports completion", function()
    vim.opt.completeopt = { "menu", "menuone", "noselect" }
    vim.cmd([[
        function! CustomComplete(arglead, cmdline, cursorpos)
          return "first\nsecond\nthird"
        endfunction
        ]])
    local ret = run_input({
      "<Tab><Tab><C-n><CR>", -- Using tab twice to test both versions of the mapping
    }, {
      completion = "custom,CustomComplete",
    })
    assert(ret == "second", string.format("Got '%s' expected 'second'", ret))
    assert(vim.fn.pumvisible() == 0, "Popup menu should not be visible after leaving modal")
  end)

  a.it("can cancel out when popup menu is open", function()
    vim.opt.completeopt = { "menu", "menuone", "noselect" }
    local ret = run_input({
      "<Tab>",
      "<C-c>",
    }, {
      completion = "command",
    })
    assert(ret == nil, string.format("Got '%s' expected nil", ret))
    assert(vim.fn.pumvisible() == 0, "Popup menu should not be visible after leaving modal")
  end)

  a.it("doesn't delete text in original buffer", function()
    -- This is a regression test for weird behavior I was seeing with the
    -- completion popup menu
    vim.api.nvim_buf_set_lines(0, 0, 1, true, { "some text" })
    vim.api.nvim_win_set_cursor(0, { 1, 4 })
    vim.opt.completeopt = { "menu", "menuone", "noselect" }
    local ret = run_input({
      "<Tab>",
      "<C-c>",
    }, {
      completion = "command",
    })
    assert(ret == nil, string.format("Got '%s' expected nil", ret))
    local line = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]
    assert(line == "some text", "Doing <C-c> with popup menu open deleted buffer text o.0")
  end)
end)
