require("plenary.async").tests.add_to_env()
local a = require("plenary.async")
local dressing = require("dressing")
local input = require("dressing.input")
local util = require("tests.util")
local channel = a.control.channel
local assert = require("luassert")
local stub = require("luassert.stub")

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

  a.it("queues successive calls to vim.ui.input", function()
    local tx1, rx1 = channel.oneshot()
    local tx2, rx2 = channel.oneshot()
    vim.ui.input({}, tx1)
    vim.ui.input({}, tx2)
    util.feedkeys({
      "i", -- HACK have to do this because :startinsert doesn't work in tests,
      "first text<CR>",
    })
    local ret = rx1()
    assert(ret == "first text", string.format("Got '%s' expected 'first text'", ret))
    a.util.sleep(10)
    util.feedkeys({
      "i", -- HACK have to do this because :startinsert doesn't work in tests,
      "second text<CR>",
    })
    ret = rx2()
    assert(ret == "second text", string.format("Got '%s' expected 'second text'", ret))
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

  local function test_start_mode(expected_start_mode, expected_restore_mode)
    -- Since going into insert mode does not work well in headless, use mocks.
    local nvim_get_mode = stub(vim.api, "nvim_get_mode", { mode = expected_restore_mode })
    local set_mode = stub(input, "set_mode")
    local restore_mode = stub(input, "restore_mode")

    local tx, rx = channel.oneshot()
    vim.ui.input({}, tx)

    assert.stub(set_mode).was_called(1)
    assert.spy(set_mode).was_called_with(expected_start_mode)
    set_mode:clear()
    assert.stub(restore_mode).was_not_called()

    util.feedkeys({ "<CR>" })

    assert.spy(set_mode).was_not_called()
    assert.stub(restore_mode).was_called(1)
    assert.stub(restore_mode).was_called_with(expected_restore_mode)

    rx()

    set_mode:revert()
    restore_mode:revert()
    nvim_get_mode:revert()
  end

  -- Visual causes problems. The other's should be enough. The logic is the same.
  for _, start_mode in ipairs({ "normal", "insert", "select" }) do
    -- Only normal and insert are supported.
    for _, mode_to_restore in ipairs({ "normal", "insert" }) do
      a.it(
        "sets the mode correctly to start_mode="
          .. start_mode
          .. " restore_mode="
          .. mode_to_restore,
        function()
          require("dressing.config").input.start_mode = start_mode
          test_start_mode(start_mode, mode_to_restore)
        end
      )
    end
  end

  a.it("is backwards compatible with start_in_insert = false", function()
    require("dressing.config").update({ input = { start_in_insert = false } })
    test_start_mode("normal", "normal")
  end)

  a.it("is backwards compatible with start_in_insert = true", function()
    require("dressing.config").update({ input = { start_in_insert = true } })
    test_start_mode("insert", "normal")
  end)

  a.it("get_config takes precedence (normal)", function()
    require("dressing.config").update({
      input = {
        start_mode = "insert",
        get_config = function()
          return { start_in_insert = false }
        end,
      },
    })
    test_start_mode("normal", "normal")
  end)

  a.it("get_config takes precedence (insert)", function()
    require("dressing.config").update({
      input = {
        start_mode = "normal",
        get_config = function()
          return { start_in_insert = true }
        end,
      },
    })
    test_start_mode("insert", "normal")
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
