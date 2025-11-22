# Tfling v2 Design Document

## Overview

Tfling v2 is a **state management library** for Neovim that provides a flexible, low-level API for plugin developers to create toggleable screen experiences. Tfling **does not create** windows, buffers, tabs, or splits. Instead, it manages the **grouping** of existing UI elements and provides lifecycle management (show/hide/toggle) for those groups.

## Core Philosophy

1. **State Management Only**: Tfling v2 focuses exclusively on grouping and lifecycle management
2. **Dynamic Registration**: UI elements are registered with experiences, not created by them
3. **Separation of Concerns**: Plugins handle creation, Tfling handles grouping and state
4. **Low-Level API**: Provides primitives for registration and lifecycle management
5. **Hook System**: Extensible through hooks that allow arbitrary functionality at key lifecycle points

## Core Concepts

### Experience

An **Experience** is a logical grouping of windows, buffers, tabs, and splits that can be managed together. It acts as a registry and lifecycle manager for UI elements.

```lua
Experience {
  id: string                    -- Unique identifier
  state: "hidden" | "visible"  -- Current state
  windows: number[]            -- Registered window IDs
  buffers: number[]            -- Registered buffer IDs
  tabs: number[]               -- Registered tabpage IDs
  metadata: table              -- Arbitrary data for hooks
  hooks: Hooks                 -- Lifecycle hooks
}
```

### Registration

UI elements are **registered** with an experience. Tfling tracks these elements and manages their visibility state, but does not create them.

```lua
-- Register a window
experience:register_window(window_id)

-- Register a buffer
experience:register_buffer(buffer_id)

-- Register a tabpage
experience:register_tab(tabpage_id)

-- Unregister elements
experience:unregister_window(window_id)
experience:unregister_buffer(buffer_id)
experience:unregister_tab(tabpage_id)
```

### Lifecycle Management

When an experience is shown/hidden, Tfling manages the visibility of all registered elements:

- **Show**: Makes registered windows/tabs visible (restores from saved state)
- **Hide**: Hides registered windows/tabs (saves state for restoration)
- **Toggle**: Switches between show/hide states

## Architecture

### State Manager

The **StateManager** is the core component that tracks all Experiences and their registered elements.

```lua
StateManager {
  experiences: Map<string, Experience>
  active_experiences: Set<string>  -- Currently visible experiences
  window_to_experience: Map<number, string>  -- Window ID -> Experience ID
  buffer_to_experience: Map<number, string>  -- Buffer ID -> Experience ID
  tab_to_experience: Map<number, string>     -- Tab ID -> Experience ID
}
```

### Window Registry

The **WindowRegistry** tracks:
- Window-to-Experience mappings
- Window configurations (for restoration when showing)
- Window visibility state

### Buffer Registry

The **BufferRegistry** tracks:
- Buffer-to-Experience mappings
- Buffer metadata (for hooks and lifecycle)

### Tab Registry

The **TabRegistry** tracks:
- Tabpage-to-Experience mappings
- Tabpage state (for restoration)

## API Design

### Core API

```lua
local tfling = require("tfling.v2")

-- Create an experience (empty, no elements yet)
local experience = tfling.create({
  id = "my-tool",
  hooks = {
    after_show = function(exp)
      print("Tool shown!")
    end,
  },
})

-- Register UI elements (created by plugin)
local win_id = vim.api.nvim_open_win(buf_id, true, { ... })
experience:register_window(win_id)

local buf_id = vim.api.nvim_create_buf(true, true)
experience:register_buffer(buf_id)

local tab_id = vim.api.nvim_create_tabpage()
experience:register_tab(tab_id)

-- Manage lifecycle
experience:show()    -- Show all registered elements
experience:hide()    -- Hide all registered elements
experience:toggle()  -- Toggle visibility

-- Query state
local state = experience.state  -- "visible" | "hidden"
```

### Registration API

```lua
-- Register elements
experience:register_window(window_id, options?)
experience:register_buffer(buffer_id, options?)
experience:register_tab(tabpage_id, options?)

-- Unregister elements
experience:unregister_window(window_id)
experience:unregister_buffer(buffer_id)
experience:unregister_tab(tabpage_id)

-- Bulk registration
experience:register({
  windows = { win_id1, win_id2 },
  buffers = { buf_id1, buf_id2 },
  tabs = { tab_id1 },
})

-- Query registered elements
local windows = experience:get_windows()
local buffers = experience:get_buffers()
local tabs = experience:get_tabs()
```

### Registration Options

```lua
RegistrationOptions {
  -- Window options
  save_config = boolean,        -- Save window config for restoration (default: true)
  restore_on_show = boolean,    -- Restore window config when showing (default: true)
  close_on_hide = boolean,      -- Close window when hiding (default: false)
  close_on_destroy = boolean,   -- Close window when destroying (default: true)
  
  -- Buffer options
  persistent = boolean,         -- Keep buffer when hiding (default: true)
  delete_on_destroy = boolean,  -- Delete buffer when destroying (default: false)
  
  -- Tab options
  close_on_hide = boolean,      -- Close tab when hiding (default: false)
  close_on_destroy = boolean,   -- Close tab when destroying (default: true)
}
```

## Lifecycle Management

### Show Operation

When an experience is shown:

1. Execute `before_show` hook
2. For each registered window:
   - If window exists and is valid: restore config and show
   - If window was closed: plugin must recreate it (via hook)
3. For each registered tab:
   - If tab exists: switch to it
   - If tab was closed: plugin must recreate it (via hook)
4. Focus the primary window (first registered window)
5. Execute `after_show` hook

### Hide Operation

When an experience is hidden:

1. Execute `before_hide` hook
2. For each registered window:
   - Save window configuration
   - Hide or close window (based on options)
3. For each registered tab:
   - Save tab state
   - Close tab if configured
4. Update state to "hidden"
5. Execute `after_hide` hook

### Window Restoration

Tfling saves window configurations when hiding:

```lua
WindowConfig {
  win_id: number
  config: table              -- nvim_win_get_config() result
  buffer_id: number          -- Buffer displayed in window
  cursor_position: [row, col]
  view_state: table          -- Scroll position, etc.
}
```

When showing, windows are restored to their saved configuration.

## Hook System

Hooks allow plugin developers to inject custom behavior at key lifecycle points:

```lua
Hooks {
  before_create: function(experience) -> nil | false  -- Return false to cancel
  after_create: function(experience) -> nil
  before_show: function(experience) -> nil | false
  after_show: function(experience) -> nil
  before_hide: function(experience) -> nil | false
  after_hide: function(experience) -> nil
  before_destroy: function(experience) -> nil | false
  after_destroy: function(experience) -> nil
  on_window_registered: function(experience, window_id) -> nil
  on_buffer_registered: function(experience, buffer_id) -> nil
  on_tab_registered: function(experience, tab_id) -> nil
  on_window_closed: function(experience, window_id) -> nil
  on_buffer_deleted: function(experience, buffer_id) -> nil
  on_tab_closed: function(experience, tab_id) -> nil
}
```

### Hook Usage Example

```lua
local experience = tfling.create({
  id = "debugger",
  hooks = {
    before_show = function(exp)
      -- Recreate windows if they were closed
      if not exp.windows[1] or not vim.api.nvim_win_is_valid(exp.windows[1]) then
        -- Plugin creates the window
        local buf = vim.api.nvim_create_buf(true, true)
        local win = vim.api.nvim_open_win(buf, true, {
          width = 80,
          height = 20,
          relative = "editor",
          row = 10,
          col = 10,
        })
        exp:register_window(win)
      end
    end,
    after_show = function(exp)
      -- Set up debugger
      vim.cmd("DebuggerStart")
    end,
    before_hide = function(exp)
      -- Clean up
      vim.cmd("DebuggerStop")
    end,
  },
})
```

## Advanced Features

### Experience Groups

Groups allow multiple experiences to be managed together:

```lua
local group = tfling.group("development")
group:add("editor")
group:add("terminal")
group:add("debugger")

-- Toggle entire group
group:toggle()

-- Show all in group
group:show()

-- Hide all in group
group:hide()
```

### Experience Dependencies

Experiences can depend on other experiences:

```lua
local editor = tfling.create({ id = "editor", ... })
local terminal = tfling.create({
  id = "terminal",
  depends_on = { "editor" },  -- Will show editor when terminal is shown
  ...
})
```

### Dynamic Registration

Elements can be registered/unregistered dynamically:

```lua
local experience = tfling.create({ id = "tool" })

-- Later, register a new window
local new_win = vim.api.nvim_open_win(buf, true, config)
experience:register_window(new_win)

-- Unregister when done
experience:unregister_window(new_win)
```

### Window Operations

Registered windows can be manipulated:

```lua
local experience = tfling.get("my-tool")

-- Resize a registered window
experience:resize_window(win_id, { width = 100, height = 50 })

-- Reposition a floating window
experience:reposition_window(win_id, { row = 20, col = 30 })

-- Focus a specific window
experience:focus_window(win_id)
```

## Usage Patterns

### Pattern 1: Plugin Creates, Tfling Manages

```lua
local function create_tool()
  -- Plugin creates the UI
  local buf = vim.api.nvim_create_buf(true, true)
  local win = vim.api.nvim_open_win(buf, true, {
    width = 80,
    height = 20,
    relative = "editor",
    row = 10,
    col = 10,
  })
  
  -- Register with Tfling
  local exp = tfling.create({ id = "my-tool" })
  exp:register_window(win)
  exp:register_buffer(buf)
  
  return exp
end

-- Later, toggle it
local tool = tfling.get("my-tool")
tool:toggle()
```

### Pattern 2: Lazy Creation via Hooks

```lua
local experience = tfling.create({
  id = "lazy-tool",
  hooks = {
    before_show = function(exp)
      -- Create windows only when showing
      if #exp.windows == 0 then
        local buf = create_buffer()
        local win = create_window(buf)
        exp:register_window(win)
        exp:register_buffer(buf)
      end
    end,
    before_hide = function(exp)
      -- Optionally close windows when hiding
      for _, win_id in ipairs(exp.windows) do
        if vim.api.nvim_win_is_valid(win_id) then
          vim.api.nvim_win_close(win_id, true)
        end
      end
      exp.windows = {}
    end,
  },
})
```

### Pattern 3: Multi-Window Experience

```lua
local function create_multi_window_tool()
  local exp = tfling.create({ id = "multi-tool" })
  
  -- Create and register multiple windows
  local buf1 = create_buffer("left")
  local win1 = vim.api.nvim_open_win(buf1, true, { ... })
  exp:register_window(win1)
  exp:register_buffer(buf1)
  
  local buf2 = create_buffer("right")
  local win2 = vim.api.nvim_open_win(buf2, true, { ... })
  exp:register_window(win2)
  exp:register_buffer(buf2)
  
  return exp
end
```

## Implementation Considerations

### Window Validation

Tfling validates registered windows before operations:

```lua
-- Check if window is valid
if vim.api.nvim_win_is_valid(win_id) then
  -- Window exists, can restore
else
  -- Window was closed, trigger recreation hook
end
```

### Buffer Persistence

Buffers can persist across hide/show cycles:

```lua
experience:register_buffer(buf_id, {
  persistent = true,  -- Buffer stays alive when hidden
})
```

### Tab Management

Tabpages are managed similarly to windows:

```lua
local tab = vim.api.nvim_create_tabpage()
experience:register_tab(tab, {
  close_on_hide = false,  -- Keep tab open when hiding
})
```

## File Structure

```
lua/tfling/v2/
  init.lua              -- Main entry point
  state.lua             -- StateManager
  experience.lua        -- Experience class
  registry.lua          -- Window/buffer/tab registries
  lifecycle.lua         -- Show/hide/toggle logic
  hooks.lua             -- Hook system
  groups.lua            -- Experience groups
  util.lua              -- Utility functions
```

## API Reference Summary

### Core Functions

- `tfling.create(opts)` - Create an experience
- `tfling.show(id)` - Show an experience
- `tfling.hide(id)` - Hide an experience
- `tfling.toggle(id)` - Toggle an experience
- `tfling.destroy(id)` - Destroy an experience
- `tfling.get(id)` - Get experience by ID
- `tfling.state(id)` - Get experience state
- `tfling.list()` - List all experiences

### Experience Methods

- `experience:register_window(win_id, options?)` - Register window
- `experience:register_buffer(buf_id, options?)` - Register buffer
- `experience:register_tab(tab_id, options?)` - Register tab
- `experience:unregister_window(win_id)` - Unregister window
- `experience:unregister_buffer(buf_id)` - Unregister buffer
- `experience:unregister_tab(tab_id)` - Unregister tab
- `experience:register(elements)` - Bulk register
- `experience:show()` - Show experience
- `experience:hide()` - Hide experience
- `experience:toggle()` - Toggle experience
- `experience:destroy()` - Destroy experience
- `experience:get_windows()` - Get registered windows
- `experience:get_buffers()` - Get registered buffers
- `experience:get_tabs()` - Get registered tabs
- `experience:resize_window(win_id, opts)` - Resize window
- `experience:reposition_window(win_id, opts)` - Reposition window
- `experience:focus_window(win_id)` - Focus window

### Groups

- `tfling.group(name)` - Create group
- `group:add(experience_id)` - Add experience
- `group:remove(experience_id)` - Remove experience
- `group:show()` - Show all
- `group:hide()` - Hide all
- `group:toggle()` - Toggle all
