# Tfling v2 Design Document

## Overview

Tfling v2 is a **state management library** for Neovim that provides a flexible, low-level API for plugin developers to create toggleable screen experiences. Tfling **does not create** windows or tabs. Instead, it manages the **grouping** of existing UI elements and provides lifecycle management (show/hide/toggle) for those groups.

## Core Philosophy

1. **State Management Only**: Focuses exclusively on grouping and lifecycle management
2. **Dynamic Registration**: UI elements are registered with experiences, not created by them
3. **Separation of Concerns**: Plugins handle creation, Tfling handles grouping and state
4. **Low-Level API**: Provides primitives for registration and lifecycle management
5. **Hook System**: Extensible through hooks that allow arbitrary functionality at key lifecycle points

## Core Concepts

### Experience

An **Experience** is a logical grouping of windows and tabs that can be managed together. It acts as a registry and lifecycle manager for UI elements. Buffers are implicitly managed through windows (windows display buffers).

```lua
Experience {
  id: string                    -- Unique identifier
  state: "hidden" | "visible"  -- Current state
  windows: number[]            -- Registered window IDs
  tabs: number[]               -- Registered tabpage IDs
  metadata: table              -- Arbitrary data for hooks
  hooks: Hooks                 -- Lifecycle hooks
}
```

### Registration

UI elements are **registered** with an experience. Tfling tracks these elements and manages their visibility state, but does not create them.

### Lifecycle Management

When an experience is shown/hidden, Tfling manages the visibility of all registered elements:
- **Show**: Makes registered windows/tabs visible (restores from saved state)
- **Hide**: Hides registered windows/tabs (saves state for restoration)
- **Toggle**: Switches between show/hide states

## API

### Core Functions

```lua
local tfling = require("tfling.v2")

-- Create an experience
local exp = tfling.create({
  id = "my-tool",
  hooks = {
    onShow = function(exp) ... end,
    onHide = function(exp) ... end,
    onDestroy = function(exp) ... end,
  },
})

-- Register UI elements (created by plugin)
local buf = vim.api.nvim_create_buf(true, true)
local win = vim.api.nvim_open_win(buf, true, { ... })
exp:register_window(win)
-- Buffers are implicitly managed through windows

-- Manage lifecycle
exp:show()
exp:hide()
exp:toggle()
exp:destroy()
```

### Registration API

```lua
-- Register elements
exp:register_window(win_id)
exp:register_tab(tab_id)

-- Unregister elements
exp:unregister_window(win_id)
exp:unregister_tab(tab_id)

-- Bulk registration
exp:register({
  windows = { win_id1, win_id2 },
  tabs = { tab_id1 },
})

-- Query registered elements
local windows = exp:get_windows()
local tabs = exp:get_tabs()
```

### Hooks

```lua
Hooks {
  onShow: function(experience) -> nil
  onHide: function(experience) -> nil
  onDestroy: function(experience) -> nil
}
```

### Window Operations

```lua
-- Resize a registered window
exp:resize_window(win_id, { width = 100, height = 50 })

-- Reposition a floating window
exp:reposition_window(win_id, { position = "bottom-right" })

-- Focus a specific window
exp:focus_window(win_id)
```

### Groups

```lua
local group = tfling.group("dev-tools")
group:add("file-tree")
group:add("terminal")
group:add("git-status")

group:toggle()  -- Toggle all experiences in group
group:show()    -- Show all
group:hide()    -- Hide all
```

## Architecture

### State Manager

Tracks all experiences and their registered elements:

```lua
StateManager {
  experiences: Map<id, Experience>
  active_experiences: Set<id>
  window_to_experience: Map<window_id, experience_id>
  tab_to_experience: Map<tab_id, experience_id>
}
```

### Lifecycle Operations

**Show:**
1. Show dependencies first
2. Restore window configurations
3. Restore tab states
4. Focus primary window
5. Execute `onShow` hook

**Hide:**
1. Hide dependents first
2. Save window configurations
3. Save tab states
4. Execute `onHide` hook

### State Saving

Tfling saves window configurations when hiding:
- Window config (`nvim_win_get_config()`)
- Buffer ID (which buffer the window displays)
- Cursor position
- View state (scroll position)
- Window options

When showing, windows are restored to their saved configuration, including the buffer they display.

## Usage Patterns

### Pattern 1: Immediate Registration

```lua
local exp = tfling.create({ id = "tool" })

-- Create and register immediately
local buf = vim.api.nvim_create_buf(true, true)
local win = vim.api.nvim_open_win(buf, true, config)
exp:register_window(win)
-- Buffer is implicitly managed through the window

exp:toggle()
```

### Pattern 2: Lazy Creation via Hooks

```lua
local exp = tfling.create({
  id = "lazy-tool",
  hooks = {
    onShow = function(exp)
      if #exp.windows == 0 then
        -- Create windows only when showing
        local buf = create_buffer()
        local win = create_window(buf)
        exp:register_window(win)
        -- Buffer is implicitly managed through the window
      end
    end,
    onHide = function(exp)
      -- Close windows when hiding
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
local exp = tfling.create({ id = "multi-tool" })

-- Create and register multiple windows
local win1 = create_window1()
local win2 = create_window2()
local win3 = create_window3()

exp:register_window(win1)
exp:register_window(win2)
exp:register_window(win3)

exp:toggle()
```

## Implementation Plan

### Phase 1: Core State Management (2-3 weeks)
- StateManager implementation
- Experience lifecycle
- Basic show/hide functionality

### Phase 2: Registration System (2-3 weeks)
- Window/tab registration APIs
- Bulk registration

### Phase 3: Lifecycle Management (2-3 weeks)
- State saving and restoration
- Window config saving/restoration
- Show/hide operations

### Phase 4: Hook System (1-2 weeks)
- Hook registration and execution
- onShow/onHide/onDestroy hooks

### Phase 5: Window Operations (1-2 weeks)
- Window resize
- Window reposition
- Window focus
- Query methods

### Phase 6: Advanced Features (2-3 weeks)
- Experience groups
- Dependency system
- Bulk operations

### Phase 7: Polish & Optimization (2-3 weeks)
- Performance optimization
- Error handling
- Documentation
- Testing

**Total Estimated Time**: 11-17 weeks (~2.5-4 months)

## File Structure

```
lua/tfling/v2/
  init.lua              -- Main entry point
  state.lua             -- StateManager
  experience.lua        -- Experience class
  registry.lua          -- Window/tab registration
  lifecycle.lua         -- Show/hide/toggle lifecycle
  hooks.lua             -- Hook system
  groups.lua            -- Experience groups
  util.lua              -- Utility functions
```

## Key Design Decisions

- **No Layout Engine**: Plugins handle window creation
- **Window/Tab Primitives Only**: Only windows and tabs are managed (buffers are implicit via windows)
- **Registration Model**: Core feature - dynamic registration of UI elements
- **State Management**: Focus on grouping and lifecycle, not creation
- **Separation of Concerns**: Clear boundary between plugin creation and Tfling management
