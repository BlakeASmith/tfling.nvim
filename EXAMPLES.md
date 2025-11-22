# Tfling v2 Usage Examples

## Basic Examples

### Simple Floating Terminal

```lua
local tfling = require("tfling.v2")

local term = tfling.create({
  id = "quick-term",
  layout = {
    type = "float",
    config = {
      width = "80%",
      height = "60%",
      position = "center",
    },
    buffer = {
      type = "terminal",
      source = "bash",
    },
  },
})

-- Toggle it
term:toggle()
```

### Terminal in Split

```lua
local term = tfling.create({
  id = "side-term",
  layout = {
    type = "split",
    config = {
      direction = "vertical",
      size = "30%",
      position = "right",
    },
    buffer = {
      type = "terminal",
      source = "htop",
    },
  },
})

term:show()
```

### File Buffer in Float

```lua
local file_viewer = tfling.create({
  id = "file-viewer",
  layout = {
    type = "float",
    config = {
      width = "70%",
      height = "80%",
      position = "center",
      border = "rounded",
    },
    buffer = {
      type = "file",
      source = "/tmp/log.txt",
      options = {
        readonly = true,
      },
    },
  },
})
```

## Advanced Layout Examples

### Development Environment

A complete development setup with editor, terminal, and file tree:

```lua
local dev_env = tfling.create({
  id = "dev-env",
  layout = {
    type = "split",
    config = {
      direction = "horizontal",
      size = "100%",
    },
    children = {
      -- File tree on left
      {
        type = "split",
        config = {
          direction = "vertical",
          size = "25%",
          position = "left",
        },
        buffer = {
          type = "function",
          source = function(exp, buf)
            vim.cmd("Oil")
          end,
        },
      },
      -- Main editor area
      {
        type = "split",
        config = {
          direction = "vertical",
          size = "75%",
        },
        children = {
          -- Editor (top)
          {
            type = "split",
            config = {
              direction = "horizontal",
              size = "70%",
            },
            buffer = {
              type = "file",
              source = "src/main.lua",
            },
          },
          -- Terminal (bottom)
          {
            type = "split",
            config = {
              direction = "horizontal",
              size = "30%",
            },
            buffer = {
              type = "terminal",
              source = "bash",
            },
          },
        },
      },
    },
  },
  hooks = {
    after_show = function(exp)
      vim.notify("Development environment ready!")
    end,
  },
})
```

### Monitoring Dashboard

Multiple floating windows showing different system metrics:

```lua
local monitoring = tfling.create({
  id = "monitoring",
  layout = {
    type = "container",
    children = {
      -- CPU monitor (top-left)
      {
        type = "float",
        config = {
          width = "45%",
          height = "45%",
          position = "top-left",
          border = "single",
        },
        buffer = {
          type = "terminal",
          source = "htop",
        },
      },
      -- I/O monitor (top-right)
      {
        type = "float",
        config = {
          width = "45%",
          height = "45%",
          position = "top-right",
          border = "single",
        },
        buffer = {
          type = "terminal",
          source = "iotop",
        },
      },
      -- Network monitor (bottom-left)
      {
        type = "float",
        config = {
          width = "45%",
          height = "45%",
          position = "bottom-left",
          border = "single",
        },
        buffer = {
          type = "terminal",
          source = "nethogs",
        },
      },
      -- Log viewer (bottom-right)
      {
        type = "float",
        config = {
          width = "45%",
          height = "45%",
          position = "bottom-right",
          border = "single",
        },
        buffer = {
          type = "file",
          source = "/var/log/syslog",
          options = {
            readonly = true,
          },
        },
      },
    },
  },
})
```

### Git Workflow

A git-focused layout with status, log, and diff views:

```lua
local git_workflow = tfling.create({
  id = "git-workflow",
  layout = {
    type = "split",
    config = {
      direction = "horizontal",
      size = "100%",
    },
    children = {
      -- Git status (left)
      {
        type = "split",
        config = {
          direction = "vertical",
          size = "30%",
        },
        children = {
          {
            type = "split",
            config = {
              direction = "horizontal",
              size = "50%",
            },
            buffer = {
              type = "terminal",
              source = "git status",
            },
          },
          {
            type = "split",
            config = {
              direction = "horizontal",
              size = "50%",
            },
            buffer = {
              type = "terminal",
              source = "git branch -a",
            },
          },
        },
      },
      -- Main diff view (right)
      {
        type = "split",
        config = {
          direction = "vertical",
          size = "70%",
        },
        buffer = {
          type = "terminal",
          source = "git diff",
        },
      },
    },
  },
  hooks = {
    before_show = function(exp)
      -- Refresh git status
      exp.metadata.last_refresh = vim.loop.now()
    end,
    after_show = function(exp)
      vim.notify("Git workflow ready")
    end,
  },
})
```

## Hook Examples

### Debugger Integration

```lua
local debugger = tfling.create({
  id = "debugger",
  layout = {
    type = "split",
    config = {
      direction = "horizontal",
      size = "100%",
    },
    children = {
      {
        type = "split",
        config = {
          direction = "vertical",
          size = "70%",
        },
        buffer = {
          type = "file",
          source = "src/main.py",
        },
      },
      {
        type = "split",
        config = {
          direction = "vertical",
          size = "30%",
        },
        buffer = {
          type = "terminal",
          source = "python -m pdb",
        },
      },
    },
  },
  hooks = {
    before_show = function(exp)
      -- Set up debugger state
      exp.metadata.debugger_attached = false
      exp.metadata.breakpoints = {}
    end,
    after_show = function(exp)
      -- Attach debugger
      local debug_window = exp.windows[2]  -- Terminal window
      vim.api.nvim_win_call(debug_window, function()
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
    end,
    on_focus = function(exp, win_id)
      -- Update statusline
      vim.g.current_debugger_window = win_id
    end,
  },
})
```

### Custom Buffer Setup

```lua
local scratchpad = tfling.create({
  id = "scratchpad",
  layout = {
    type = "float",
    config = {
      width = "60%",
      height = "70%",
      position = "center",
    },
    buffer = {
      type = "scratch",
      options = {
        filetype = "markdown",
      },
    },
  },
  hooks = {
    after_show = function(exp)
      -- Set up buffer content and keymaps
      local buf_id = exp.buffers[1]
      
      -- Set initial content
      vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, {
        "# Scratchpad",
        "",
        "Write your notes here...",
        "",
      })
      
      -- Set up keymaps
      vim.keymap.set("n", "q", function()
        exp:hide()
      end, { buffer = buf_id, silent = true })
      
      vim.keymap.set("n", "<C-s>", function()
        vim.cmd("w /tmp/scratchpad.md")
        vim.notify("Saved to /tmp/scratchpad.md")
      end, { buffer = buf_id, silent = true })
    end,
  },
})
```

### Session Management

```lua
local persistent_term = tfling.create({
  id = "persistent-term",
  layout = {
    type = "float",
    config = {
      width = "80%",
      height = "60%",
      position = "center",
    },
    buffer = {
      type = "terminal",
      source = "tmux",
      options = {
        tmux = true,
        persistent = true,
      },
    },
  },
  hooks = {
    before_hide = function(exp)
      -- Save tmux session state
      local buf_id = exp.buffers[1]
      if exp.buffer_specs[buf_id].job_id then
        -- Send detach command to tmux
        vim.api.nvim_chan_send(
          exp.buffer_specs[buf_id].job_id,
          vim.api.nvim_replace_termcodes("<C-b>d", true, false, true)
        )
      end
    end,
    after_show = function(exp)
      -- Restore tmux session
      vim.notify("Tmux session restored")
    end,
  },
})
```

## Group Examples

### Development Tools Group

```lua
local dev_tools = tfling.group("dev-tools")

-- Add multiple experiences
dev_tools:add("file-tree")
dev_tools:add("terminal")
dev_tools:add("git-status")
dev_tools:add("lsp-output")

-- Toggle entire group
vim.keymap.set("n", "<leader>dt", function()
  dev_tools:toggle()
end)

-- Show all tools
vim.keymap.set("n", "<leader>ds", function()
  dev_tools:show()
end)

-- Hide all tools
vim.keymap.set("n", "<leader>dh", function()
  dev_tools:hide()
end)
```

### Workspace Presets

```lua
-- Frontend workspace
local frontend_workspace = tfling.group("frontend")
frontend_workspace:add("file-tree")
frontend_workspace:add("terminal")
frontend_workspace:add("browser-preview")

-- Backend workspace
local backend_workspace = tfling.group("backend")
backend_workspace:add("file-tree")
backend_workspace:add("terminal")
backend_workspace:add("database-client")
backend_workspace:add("api-docs")

-- Switch workspaces
vim.keymap.set("n", "<leader>wf", function()
  backend_workspace:hide()
  frontend_workspace:show()
end)

vim.keymap.set("n", "<leader>wb", function()
  frontend_workspace:hide()
  backend_workspace:show()
end)
```

## Layout Builder Examples

### Fluent API

```lua
local tfling = require("tfling.v2")

-- Build complex layout using fluent API
local layout = tfling.layout()
  :split("horizontal", { size = "100%" })
    :split("vertical", { size = "30%", position = "left" })
      :buffer({ type = "file", source = "filetree" })
    :end_split()
    :split("vertical", { size = "70%" })
      :split("horizontal", { size = "70%" })
        :buffer({ type = "file", source = "src/main.lua" })
      :end_split()
      :split("horizontal", { size = "30%" })
        :buffer({ type = "terminal", source = "bash" })
      :end_split()
    :end_split()
  :end_split()
  :build()

local experience = tfling.create({
  id = "dev-layout",
  layout = layout,
})
```

## Dynamic Layout Modification

### Resizable Panels

```lua
local resizable = tfling.create({
  id = "resizable",
  layout = {
    type = "split",
    config = {
      direction = "horizontal",
      size = "100%",
    },
    children = {
      {
        type = "split",
        config = {
          direction = "vertical",
          size = "30%",
        },
        buffer = { type = "file", source = "left.txt" },
      },
      {
        type = "split",
        config = {
          direction = "vertical",
          size = "70%",
        },
        buffer = { type = "file", source = "right.txt" },
      },
    },
  },
})

-- Resize left panel
vim.keymap.set("n", "<leader>rl", function()
  local left_win = resizable.windows[1]
  resizable:resize_window(left_win, { width = "+10%" })
end)

-- Resize right panel
vim.keymap.set("n", "<leader>rr", function()
  local right_win = resizable.windows[2]
  resizable:resize_window(right_win, { width = "+10%" })
end)
```

## Plugin Integration Examples

### LSP Integration

```lua
local lsp_diagnostics = tfling.create({
  id = "lsp-diagnostics",
  layout = {
    type = "float",
    config = {
      width = "50%",
      height = "40%",
      position = "bottom-right",
    },
    buffer = {
      type = "scratch",
      options = {
        filetype = "lsp-diagnostics",
      },
    },
  },
  hooks = {
    after_show = function(exp)
      local buf_id = exp.buffers[1]
      
      -- Populate with LSP diagnostics
      local diagnostics = vim.diagnostic.get(0)
      local lines = {}
      for _, diag in ipairs(diagnostics) do
        table.insert(lines, string.format(
          "[%s] %s:%d:%d - %s",
          diag.severity,
          vim.fn.bufname(diag.bufnr),
          diag.lnum + 1,
          diag.col + 1,
          diag.message
        ))
      end
      
      vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
    end,
  },
})

-- Show diagnostics on demand
vim.keymap.set("n", "<leader>ld", function()
  lsp_diagnostics:toggle()
end)
```

### File Explorer Integration

```lua
local file_explorer = tfling.create({
  id = "file-explorer",
  layout = {
    type = "split",
    config = {
      direction = "vertical",
      size = "25%",
      position = "left",
    },
    buffer = {
      type = "function",
      source = function(exp, buf)
        -- Use Oil.nvim or similar
        vim.cmd("Oil")
      end,
    },
  },
  hooks = {
    after_show = function(exp)
      -- Set up file explorer keymaps
      local buf_id = exp.buffers[1]
      vim.keymap.set("n", "q", function()
        exp:hide()
      end, { buffer = buf_id, silent = true })
    end,
  },
})
```

### Quickfix Integration

```lua
local quickfix = tfling.create({
  id = "quickfix",
  layout = {
    type = "float",
    config = {
      width = "80%",
      height = "30%",
      position = "bottom-center",
    },
    buffer = {
      type = "function",
      source = function(exp, buf)
        vim.cmd("copen")
        -- Get quickfix buffer
        local qf_buf = vim.fn.getqflist({ bufnr = 0 }).bufnr
        return qf_buf
      end,
    },
  },
})

vim.keymap.set("n", "<leader>qf", function()
  quickfix:toggle()
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
    layout = {
      type = "split",
      config = {
        direction = "horizontal",
        size = "100%",
      },
      children = {
        {
          type = "split",
          config = {
            direction = "vertical",
            size = "30%",
          },
          buffer = {
            type = "scratch",
            options = {
              filetype = "my-plugin-list",
            },
          },
        },
        {
          type = "split",
          config = {
            direction = "vertical",
            size = "70%",
          },
          buffer = {
            type = "scratch",
            options = {
              filetype = "my-plugin-detail",
            },
          },
        },
      },
    },
    hooks = {
      after_show = function(exp)
        -- Initialize plugin UI
        M._init_ui(exp)
      end,
      before_hide = function(exp)
        -- Save state
        M._save_state(exp)
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

function M._init_ui(exp)
  local list_buf = exp.buffers[1]
  local detail_buf = exp.buffers[2]
  
  -- Populate list buffer
  vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, {
    "Item 1",
    "Item 2",
    "Item 3",
  })
  
  -- Set up keymaps
  vim.keymap.set("n", "q", function()
    exp:hide()
  end, { buffer = list_buf })
  
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    M._show_detail(exp, line)
  end, { buffer = list_buf })
end

function M._show_detail(exp, item)
  local detail_buf = exp.buffers[2]
  vim.api.nvim_buf_set_lines(detail_buf, 0, -1, false, {
    "Detail for: " .. item,
    "",
    "More information here...",
  })
end

function M._save_state(exp)
  -- Save plugin state
  exp.metadata.last_state = {
    timestamp = vim.loop.now(),
    -- ... other state
  }
end

return M
```

This example shows how a plugin developer would use Tfling v2 to create a toggleable UI with multiple panels, custom buffers, and lifecycle hooks.
