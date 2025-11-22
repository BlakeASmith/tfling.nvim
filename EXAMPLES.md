# Tfling v2 Usage Examples

## Basic Examples

### Simple Floating Window

```lua
local tfling = require("tfling.v2")

-- Create experience
local exp = tfling.create({
  id = "quick-tool",
})

-- Plugin creates the window
local buf = vim.api.nvim_create_buf(true, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Hello, World!" })

local win = vim.api.nvim_open_win(buf, true, {
  relative = "editor",
  width = 50,
  height = 10,
  row = 10,
  col = 30,
  border = "rounded",
})

-- Register with Tfling
exp:register_window(win)
exp:register_buffer(buf)

-- Toggle it
exp:toggle()
```

### Terminal in Split

```lua
local tfling = require("tfling.v2")

local exp = tfling.create({
  id = "side-term",
})

-- Create terminal buffer
local buf = vim.api.nvim_create_buf(true, true)
vim.bo[buf].bufhidden = "hide"
vim.bo[buf].filetype = "tfling"

-- Create split window
vim.cmd("botright vsplit")
vim.cmd("vertical resize 30")
local win = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_buf(win, buf)

-- Start terminal
local job_id = vim.fn.termopen("bash", {
  on_exit = function()
    -- Handle exit
  end,
})

-- Register with Tfling
exp:register_window(win, {
  close_on_hide = false,  -- Keep window open when hiding
})
exp:register_buffer(buf, {
  persistent = true,
})
```

### File Buffer in Float

```lua
local tfling = require("tfling.v2")

local exp = tfling.create({
  id = "file-viewer",
})

-- Open file buffer
local buf = vim.fn.bufadd("/tmp/log.txt")
vim.fn.bufload(buf)

-- Create floating window
local win = vim.api.nvim_open_win(buf, true, {
  relative = "editor",
  width = 70,
  height = 40,
  row = 5,
  col = 10,
  border = "single",
})

-- Register
exp:register_window(win)
exp:register_buffer(buf, {
  persistent = true,
})
```

## Advanced Examples

### Lazy Creation Pattern

Create windows only when showing:

```lua
local tfling = require("tfling.v2")

local exp = tfling.create({
  id = "lazy-tool",
  hooks = {
    before_show = function(exp)
      -- Create windows only when showing
      if #exp.windows == 0 then
        local buf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
          "This window was created on show",
        })
        
        local win = vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          width = 60,
          height = 20,
          row = 10,
          col = 20,
        })
        
        exp:register_window(win)
        exp:register_buffer(buf)
      end
    end,
    before_hide = function(exp)
      -- Close windows when hiding
      for _, win_id in ipairs(exp.windows) do
        if vim.api.nvim_win_is_valid(win_id) then
          vim.api.nvim_win_close(win_id, true)
        end
      end
      exp.windows = {}
      exp.buffers = {}
    end,
  },
})

-- Toggle will create/destroy windows
exp:toggle()
```

### Multi-Window Experience

```lua
local tfling = require("tfling.v2")

local function create_multi_window_tool()
  local exp = tfling.create({
    id = "multi-tool",
  })
  
  -- Create left window
  local buf1 = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_lines(buf1, 0, -1, false, { "Left Panel" })
  local win1 = vim.api.nvim_open_win(buf1, true, {
    relative = "editor",
    width = 40,
    height = 30,
    row = 5,
    col = 5,
  })
  
  -- Create right window
  local buf2 = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_lines(buf2, 0, -1, false, { "Right Panel" })
  local win2 = vim.api.nvim_open_win(buf2, true, {
    relative = "editor",
    width = 40,
    height = 30,
    row = 5,
    col = 50,
  })
  
  -- Register all
  exp:register_window(win1)
  exp:register_window(win2)
  exp:register_buffer(buf1)
  exp:register_buffer(buf2)
  
  return exp
end

local tool = create_multi_window_tool()
tool:toggle()
```

### Development Environment

```lua
local tfling = require("tfling.v2")

local function create_dev_env()
  local exp = tfling.create({
    id = "dev-env",
    hooks = {
      before_show = function(exp)
        if #exp.windows > 0 then
          return  -- Already created
        end
        
        -- File tree (left split)
        vim.cmd("topleft vsplit")
        vim.cmd("vertical resize 25")
        local tree_win = vim.api.nvim_get_current_win()
        local tree_buf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_win_set_buf(tree_win, tree_buf)
        vim.cmd("Oil")  -- Or your file tree plugin
        
        -- Main editor (right split)
        vim.cmd("wincmd l")
        vim.cmd("split")
        local editor_win = vim.api.nvim_get_current_win()
        local editor_buf = vim.fn.bufadd("src/main.lua")
        vim.fn.bufload(editor_buf)
        vim.api.nvim_win_set_buf(editor_win, editor_buf)
        
        -- Terminal (bottom split)
        vim.cmd("wincmd j")
        local term_win = vim.api.nvim_get_current_win()
        local term_buf = vim.api.nvim_create_buf(true, true)
        vim.bo[term_buf].bufhidden = "hide"
        vim.api.nvim_win_set_buf(term_win, term_buf)
        vim.fn.termopen("bash")
        
        -- Register all
        exp:register_window(tree_win)
        exp:register_window(editor_win)
        exp:register_window(term_win)
        exp:register_buffer(tree_buf)
        exp:register_buffer(editor_buf)
        exp:register_buffer(term_buf)
      end,
      before_hide = function(exp)
        -- Close all windows
        for _, win_id in ipairs(exp.windows) do
          if vim.api.nvim_win_is_valid(win_id) then
            vim.api.nvim_win_close(win_id, true)
          end
        end
        exp.windows = {}
        exp.buffers = {}
      end,
    },
  })
  
  return exp
end

local dev_env = create_dev_env()
dev_env:toggle()
```

## Hook Examples

### Debugger Integration

```lua
local tfling = require("tfling.v2")

local debugger = tfling.create({
  id = "debugger",
  hooks = {
    before_show = function(exp)
      if #exp.windows > 0 then
        return
      end
      
      -- Create editor window
      local editor_buf = vim.fn.bufadd("src/main.py")
      vim.fn.bufload(editor_buf)
      vim.cmd("split")
      local editor_win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(editor_win, editor_buf)
      
      -- Create debugger terminal
      vim.cmd("wincmd j")
      local debug_buf = vim.api.nvim_create_buf(true, true)
      vim.bo[debug_buf].bufhidden = "hide"
      local debug_win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(debug_win, debug_buf)
      vim.fn.termopen("python -m pdb")
      
      exp:register_window(editor_win)
      exp:register_window(debug_win)
      exp:register_buffer(editor_buf)
      exp:register_buffer(debug_buf)
      
      exp.metadata.debugger_attached = false
    end,
    after_show = function(exp)
      -- Attach debugger
      local debug_win = exp.windows[2]
      vim.api.nvim_win_call(debug_win, function()
        vim.cmd("DebuggerStart")
        exp.metadata.debugger_attached = true
      end)
    end,
    before_hide = function(exp)
      -- Detach debugger
      if exp.metadata.debugger_attached then
        vim.cmd("DebuggerStop")
        exp.metadata.debugger_attached = false
      end
      
      -- Close windows
      for _, win_id in ipairs(exp.windows) do
        if vim.api.nvim_win_is_valid(win_id) then
          vim.api.nvim_win_close(win_id, true)
        end
      end
      exp.windows = {}
      exp.buffers = {}
    end,
  },
})
```

### Custom Buffer Setup

```lua
local tfling = require("tfling.v2")

local scratchpad = tfling.create({
  id = "scratchpad",
  hooks = {
    before_show = function(exp)
      if #exp.windows > 0 then
        return
      end
      
      local buf = vim.api.nvim_create_buf(true, true)
      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].filetype = "markdown"
      
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "# Scratchpad",
        "",
        "Write your notes here...",
        "",
      })
      
      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = 60,
        height = 30,
        row = 10,
        col = 20,
      })
      
      -- Set up keymaps
      vim.keymap.set("n", "q", function()
        exp:hide()
      end, { buffer = buf, silent = true })
      
      vim.keymap.set("n", "<C-s>", function()
        vim.cmd("w /tmp/scratchpad.md")
        vim.notify("Saved to /tmp/scratchpad.md")
      end, { buffer = buf, silent = true })
      
      exp:register_window(win)
      exp:register_buffer(buf)
    end,
    before_hide = function(exp)
      for _, win_id in ipairs(exp.windows) do
        if vim.api.nvim_win_is_valid(win_id) then
          vim.api.nvim_win_close(win_id, true)
        end
      end
      exp.windows = {}
      exp.buffers = {}
    end,
  },
})
```

## Group Examples

### Development Tools Group

```lua
local tfling = require("tfling.v2")

-- Create experiences
local file_tree = tfling.create({ id = "file-tree" })
local terminal = tfling.create({ id = "terminal" })
local git_status = tfling.create({ id = "git-status" })

-- Set up each experience...
-- (registration code omitted for brevity)

-- Create group
local dev_tools = tfling.group("dev-tools")
dev_tools:add("file-tree")
dev_tools:add("terminal")
dev_tools:add("git-status")

-- Toggle entire group
vim.keymap.set("n", "<leader>dt", function()
  dev_tools:toggle()
end)
```

## Real-World Plugin Example

### A Complete Plugin Using Tfling v2

```lua
-- my-plugin.lua
local tfling = require("tfling.v2")

local M = {}

function M.setup(opts)
  opts = opts or {}
  
  -- Create main experience
  local main_exp = tfling.create({
    id = "my-plugin-main",
    hooks = {
      before_show = function(exp)
        if #exp.windows > 0 then
          return  -- Already shown
        end
        
        -- Create list window (left)
        local list_buf = vim.api.nvim_create_buf(true, true)
        vim.bo[list_buf].filetype = "my-plugin-list"
        vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, {
          "Item 1",
          "Item 2",
          "Item 3",
        })
        
        vim.cmd("topleft vsplit")
        vim.cmd("vertical resize 30")
        local list_win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(list_win, list_buf)
        
        -- Create detail window (right)
        local detail_buf = vim.api.nvim_create_buf(true, true)
        vim.bo[detail_buf].filetype = "my-plugin-detail"
        
        vim.cmd("wincmd l")
        local detail_win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(detail_win, detail_buf)
        
        -- Register
        exp:register_window(list_win)
        exp:register_window(detail_win)
        exp:register_buffer(list_buf)
        exp:register_buffer(detail_buf)
        
        -- Set up keymaps
        vim.keymap.set("n", "q", function()
          exp:hide()
        end, { buffer = list_buf })
        
        vim.keymap.set("n", "<CR>", function()
          local line = vim.api.nvim_get_current_line()
          M._show_detail(exp, line)
        end, { buffer = list_buf })
      end,
      before_hide = function(exp)
        -- Close windows
        for _, win_id in ipairs(exp.windows) do
          if vim.api.nvim_win_is_valid(win_id) then
            vim.api.nvim_win_close(win_id, true)
          end
        end
        exp.windows = {}
        exp.buffers = {}
      end,
    },
  })
  
  -- Store reference
  M.experience = main_exp
  
  -- Set up keymaps
  vim.keymap.set("n", opts.toggle_key or "<leader>mp", function()
    main_exp:toggle()
  end)
end

function M._show_detail(exp, item)
  local detail_buf = exp.buffers[2]
  vim.api.nvim_buf_set_lines(detail_buf, 0, -1, false, {
    "Detail for: " .. item,
    "",
    "More information here...",
  })
end

return M
```

## Registration Options Examples

### Persistent Windows

```lua
local exp = tfling.create({ id = "tool" })

local win = create_window()
exp:register_window(win, {
  close_on_hide = false,  -- Keep window open when hiding
  save_config = true,     -- Save config for restoration
  restore_on_show = true, -- Restore config when showing
})
```

### Ephemeral Windows

```lua
local exp = tfling.create({ id = "tool" })

local win = create_window()
exp:register_window(win, {
  close_on_hide = true,   -- Close when hiding
  close_on_destroy = true, -- Close when destroying
})
```

### Persistent Buffers

```lua
local exp = tfling.create({ id = "tool" })

local buf = create_buffer()
exp:register_buffer(buf, {
  persistent = true,       -- Keep buffer alive when hidden
  delete_on_destroy = false, -- Don't delete on destroy
})
```

## Dynamic Registration

```lua
local exp = tfling.create({ id = "dynamic-tool" })

-- Register initial window
local win1 = create_window()
exp:register_window(win1)

-- Later, add more windows dynamically
local win2 = create_window()
exp:register_window(win2)

-- Remove a window
exp:unregister_window(win1)
```

## Window Operations

```lua
local exp = tfling.get("my-tool")

-- Resize a registered window
exp:resize_window(exp.windows[1], {
  width = 100,
  height = 50,
})

-- Reposition a floating window
exp:reposition_window(exp.windows[1], {
  row = 20,
  col = 30,
})

-- Focus a specific window
exp:focus_window(exp.windows[1])
```
