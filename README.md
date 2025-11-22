# tfling.nvim

A terminal window plugin (++)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "BlakeASmith/tfling.nvim",
  config = function()
    require("tfling").setup({
      -- your configuration here
    })
  end
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "BlakeASmith/tfling.nvim",
  config = function()
    require("tfling").setup({
      -- your configuration here
    })
  end
}
```

## Configuration

```lua
require("tfling").setup({
  -- Global callback for all terminal instances
  always = function(term_details)
    -- term_details contains: job_id, bufnr, win_id, name, cmd, selected_text, send, win
  end,
  -- Delay in milliseconds before sending commands (default: 100)
  send_delay = 100,
})
```

## Features

### Tmux Integration

tfling.nvim includes built-in tmux integration that allows you to create persistent terminal sessions backed by tmux. This is particularly useful for long-running processes or when you want to maintain terminal state across Neovim sessions.

#### Basic Usage

```lua
-- Create a tmux-backed terminal
require("tfling").term({
  name = "my-session",
  cmd = "htop",
  tmux = true,  -- Enable tmux integration
  win = {
    type = "floating",
    position = "right-center",
    width = "60%",
    height = "40%",
  },
})
```

#### Tmux Features

- **Session Management**: Automatically creates tmux sessions with the naming pattern `tfling-{name}`
- **Session Persistence**: Sessions persist even when the Neovim terminal window is closed
- **Session Reuse**: If a session already exists, it will attach to the existing session instead of creating a new one
- **Command Execution**: The specified command runs within the tmux session

#### Available Functions

The tmux module provides several utility functions:

```lua
local tmux = require("tfling.tmux")

-- Check if a session exists
local exists = tmux.session_exists("my-session")

-- Create or attach to a session
local cmd = tmux.session({
  name = "my-session",
  start_cmd = {"htop"},  -- Optional: command to run in the session
})

-- Kill a session
tmux.kill_session({
  name = "my-session",
})

-- Get attach command for a session
local attach_cmd = tmux.attach_session({
  name = "my-session",
})
```

#### Example Use Cases

1. **Development Servers**: Keep your development server running in a tmux session
2. **Long-running Processes**: Monitor system resources with tools like `htop` or `iotop`
3. **Database Connections**: Maintain persistent database connections
4. **Build Processes**: Keep build processes running in the background

### Generic Buffers

You can also use tfling to manage regular buffers using `M.buff`. This allows you to open any file or run any Vim command in a floating or split window with the same window management capabilities as terminals.

#### Examples

**Open Oil.nvim as a file manager:**

```lua
require("tfling").buff({
  name = "file_manager",
  init = "Oil", -- Vim command to run
  win = {
    type = "floating",
    position = "center",
    width = "80%",
    height = "80%",
  },
})
```

**Open Netrw:**

```lua
require("tfling").buff({
  name = "netrw",
  init = "Ex",
  win = {
    position = "left-center",
    width = "30%",
  },
})
```

**Quick Access to init.lua:**

```lua
require("tfling").buff({
  name = "config",
  init = "edit $MYVIMRC",
  win = {
    type = "floating",
    width = "70%",
    height = "70%",
  },
})
```

**Custom Lua Initialization:**

```lua
require("tfling").buff({
  name = "scratchpad",
  init = function(term)
    -- 'term' is the tfling instance
    -- Set buffer content, options, etc.
    vim.api.nvim_buf_set_lines(term.bufnr, 0, -1, false, {
      "# Scratchpad",
      "",
      "Write your notes here...",
    })
    vim.bo[term.bufnr].filetype = "markdown"
  end,
  win = {
    position = "right-center",
    width = "40%",
  },
})
```

**Setting Custom Keybinds:**

The `setup` function runs every time the buffer is entered, making it ideal for setting buffer-local keymaps.

```lua
require("tfling").buff({
  name = "my_tool",
  init = "Man bash",
  setup = function(term)
    -- Set a keymap to close the window with 'q'
    vim.keymap.set("n", "q", function()
      vim.api.nvim_win_close(term.win_id, true)
    end, { buffer = term.bufnr, silent = true })
    
    -- Set a keymap to resize the window
    vim.keymap.set("n", "<C-Right>", function()
      term.win.resize({ width = "+5%" })
    end, { buffer = term.bufnr, silent = true })
  end,
  win = {
    width = "60%",
    height = "80%",
  },
})
```

**Multiple Commands with Pipe:**

You can chain multiple Vim commands using the `|` separator in the `init` string.

```lua
require("tfling").buff({
  name = "split_view",
  init = "e file1.txt | vsplit file2.txt", -- Opens file1, then splits and opens file2
  win = {
    width = "90%",
    height = "90%",
  },
})
```

## License

MIT
