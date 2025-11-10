local M = {}

M.options = {
  window = {
    width = 0.5,        -- Default width as a fraction of the screen
    height = 0.5,       -- Default height as a fraction of the screen
    border = 'rounded', -- Default border style
  },
}

M.setup = function(opts)
  opts = opts or {}
  vim.tbl_deep_extend('force', M.options, opts)
end

-- Base picker function that takes a table of items and a callback
M.base_picker = function(items, on_select)
  if #items == 0 then
    return
  end

  if not on_select then
    on_select = function(selected)
      print(selected)
    end
  end

  -- Ensure items are strings for display
  local display_items = {}
  for i, item in ipairs(items) do
    if type(item) == "string" then
      display_items[i] = item
    else
      display_items[i] = tostring(item)
    end
  end

  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_items)

  -- Calculate window dimensions
  local width = math.floor(vim.o.columns * M.options.window.width)
  local height = math.min(#items, math.floor(vim.o.lines * M.options.window.height))
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = M.options.window.border,
  }

  -- Open the floating window
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set buffer options
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })

  -- Highlight current line
  vim.api.nvim_set_option_value('cursorline', true, { win = win })

  local get_cursor_line = function()
    return vim.api.nvim_win_get_cursor(win)[1]
  end

  -- Key mappings
  local current_line = 1
  vim.api.nvim_win_set_cursor(win, { current_line, 0 })

  vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '', {
    callback = function()
      local cursor_line = get_cursor_line()
      local selected = display_items[cursor_line]
      vim.api.nvim_win_close(win, true)
      on_select(selected)
    end
  })

  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '', {
    callback = function()
      vim.api.nvim_win_close(win, true)
    end
  })

  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '', {
    callback = function()
      vim.api.nvim_win_close(win, true)
    end
  })
end

M.setup()
M.base_picker({ "apple", "banana", "cherry", "date", "elderberry", "fig", "grape", "honeydew", "kiwi", "lemon", "mango",
  "nectarine", "orange", "papaya", "quince", "raspberry", "strawberry", "tangerine", "ugli", "vanilla", "watermelon",
  "xigua", "yuzu", "zucchini", "apricot", "blackberry", "cantaloupe", "dragonfruit", "eggplant", "feijoa", "guava",
  "huckleberry", "jackfruit", "kumquat", "lime", "mulberry", "nutmeg", "olive", "peach", "pear", "rhubarb", "starfruit",
  "tomato", "avocado", "blueberry", "coconut", "durian", "elderflower", "grapefruit", "hazelnut", "iceberg", "jujube",
  "kale", "lettuce", "mushroom", "onion", "potato", "quinoa", "radish", "spinach", "turnip", "upland", "violet", "walnut",
  "ximenia", "yam", "zest", "artichoke", "broccoli", "carrot", "dill", "endive", "fennel", "ginger", "horseradish", "ivy",
  "jalapeno", "kohlrabi", "leek", "mint", "nasturtium", "oregano", "parsley", "quail", "rosemary", "sage", "thyme",
  "umami", "verbena", "wasabi", "xerophyte", "yarrow", "zephyr", "almond", "basil", "cilantro", "dandelion", "eucalyptus",
  "fern", "garlic", "hibiscus", "iris", "jasmine" })

return M
