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

## License

MIT
