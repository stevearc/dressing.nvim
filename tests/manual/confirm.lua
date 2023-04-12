-- Run this test with :source %

local function run_test()
  vim.ui.confirm("Pick a fruit", { choices = { "Apple", "Banana", "O&range" } }, function(idx, text)
    if idx then
      vim.notify(string.format("selected '%d' (%s)", idx, text), vim.log.levels.INFO)
    else
      vim.notify("Canceled", vim.log.levels.INFO)
    end
  end)
end

-- Replace this with the desired backend to test
run_test()
