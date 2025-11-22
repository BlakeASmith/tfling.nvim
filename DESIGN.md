# Tfling v2 Design Document

## Overview

Tfling v2 is a state management library for Neovim that provides a flexible, low-level API for plugin developers to create toggleable screen experiences. It abstracts away the complexity of managing windows, tabs, splits, and floating windows into logical groupings that can be toggled on and off as cohesive units.

## Core Philosophy

1. **State Management First**: Tfling v2 is fundamentally about managing the state of Neovim's UI elements (windows, tabs, buffers)
2. **Logical Groupings**: Related UI elements are grouped together into "Experiences" that can be toggled as a unit
3. **Low-Level API**: Provides primitives that plugin developers can compose into higher-level abstractions
4. **Hook System**: Extensible through hooks that allow arbitrary functionality at key lifecycle points
5. **Layout Agnostic**: Supports any combination of splits, tabs, and floating windows

## Core Concepts

### Experience

An **Experience** is the fundamental unit of state management in Tfling v2. It represents a logical grouping of windows/tabs/splits that together form a cohesive user experience.

```lua
Experience {
  id: string                    -- Unique identifier
  state: "hidden" | "visible"  -- Current state
  layout: Layout               -- Defines the structure
  metadata: table              -- Arbitrary data for hooks
  hooks: Hooks                 -- Lifecycle hooks
}
```

### Layout

A **Layout** defines the structure of windows, tabs, and splits that make up an Experience. Layouts are hierarchical and can be nested.

```lua
Layout {
  type: "split" | "tab" | "float" | "container"
  children: Layout[]           -- For container types
  config: LayoutConfig         -- Type-specific configuration
  buffer: BufferSpec          -- What to display
}
```

### Buffer Specification

A **BufferSpec** describes what content should be displayed in a window. It can be:
- A terminal command
- An existing buffer number
- A buffer creation function
- A file path

```lua
BufferSpec {
  type: "terminal" | "buffer" | "file" | "function"
  source: string | number | function
  options: BufferOptions
}
```

### Hooks

**Hooks** allow plugin developers to inject custom behavior at key lifecycle points:

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
  on_focus: function(experience, window_id) -> nil
  on_buffer_enter: function(experience, buffer_id) -> nil
}
```

## Architecture

### State Manager

The **StateManager** is the core component that tracks all Experiences and their states.

```lua
StateManager {
  experiences: Map<string, Experience>
  active_experiences: Set<string>  -- Currently visible experiences
  window_to_experience: Map<number, string>  -- Window ID -> Experience ID
  buffer_to_experience: Map<number, string>  -- Buffer ID -> Experience ID
}
```

### Layout Engine

The **LayoutEngine** is responsible for:
- Creating windows/tabs/splits according to Layout specifications
- Restoring window configurations when showing hidden experiences
- Managing window relationships and hierarchies
- Handling window cleanup

### Window Registry

The **WindowRegistry** tracks:
- Window-to-Experience mappings
- Window configurations (for restoration)
- Window hierarchies (parent/child relationships)

## API Design

### Core API

```lua
local tfling = require("tfling.v2")

-- Create an experience
local experience = tfling.create({
  id = "my-tool",
  layout = {
    type = "float",
    config = {
      width = "80%",
      height = "80%",
      position = "center",
    },
    buffer = {
      type = "terminal",
      source = "htop",
    },
  },
  hooks = {
    after_show = function(exp)
      print("Tool shown!")
    end,
  },
})

-- Toggle an experience
tfling.toggle("my-tool")

-- Show an experience
tfling.show("my-tool")

-- Hide an experience
tfling.hide("my-tool")

-- Get experience state
local state = tfling.state("my-tool")  -- "visible" | "hidden" | nil

-- Destroy an experience
tfling.destroy("my-tool")
```

### Layout Builder API

For complex layouts, a builder pattern provides a fluent API:

```lua
local layout = tfling.layout()
  :split("horizontal", { size = "30%" })
    :buffer({ type = "terminal", source = "htop" })
    :split("vertical", { size = "50%" })
      :buffer({ type = "file", source = "/tmp/log.txt" })
      :buffer({ type = "terminal", source = "tail -f /var/log/syslog" })
  :end_split()
:build()

local experience = tfling.create({
  id = "monitoring",
  layout = layout,
})
```

### Advanced Layout Examples

#### Multi-Split Layout

```lua
local layout = {
  type = "split",
  direction = "horizontal",
  config = { size = "100%" },
  children = {
    {
      type = "split",
      direction = "vertical",
      config = { size = "50%" },
      children = {
        {
          type = "float",
          config = { width = "40%", height = "60%", position = "top-left" },
          buffer = { type = "terminal", source = "htop" },
        },
        {
          type = "float",
          config = { width = "40%", height = "60%", position = "top-right" },
          buffer = { type = "terminal", source = "iotop" },
        },
      },
    },
    {
      type = "split",
      direction = "vertical",
      config = { size = "50%" },
      children = {
        {
          type = "float",
          config = { width = "40%", height = "60%", position = "bottom-left" },
          buffer = { type = "file", source = "/tmp/errors.log" },
        },
        {
          type = "float",
          config = { width = "40%", height = "60%", position = "bottom-right" },
          buffer = { type = "terminal", source = "journalctl -f" },
        },
      },
    },
  },
}
```

#### Tab-Based Layout

```lua
local layout = {
  type = "tab",
  config = {},
  children = {
    {
      type = "split",
      direction = "horizontal",
      config = { size = "100%" },
      children = {
        {
          type = "split",
          direction = "vertical",
          config = { size = "30%" },
          buffer = { type = "file", source = "src/main.lua" },
        },
        {
          type = "split",
          direction = "vertical",
          config = { size = "70%" },
          buffer = { type = "terminal", source = "lua src/main.lua" },
        },
      },
    },
    {
      type = "float",
      config = { width = "90%", height = "90%", position = "center" },
      buffer = { type = "file", source = "README.md" },
    },
  },
}
```

#### Mixed Layout (Splits + Floats)

```lua
local layout = {
  type = "container",
  children = {
    {
      type = "split",
      direction = "vertical",
      config = { size = "30%", position = "left" },
      buffer = { type = "file", source = "filetree" },
    },
    {
      type = "float",
      config = { width = "50%", height = "80%", position = "center" },
      buffer = { type = "terminal", source = "git log --oneline" },
    },
    {
      type = "float",
      config = { width = "30%", height = "40%", position = "bottom-right" },
      buffer = { type = "terminal", source = "git status" },
    },
  },
}
```

## State Management

### Experience Lifecycle

1. **Created**: Experience is registered but not yet shown
2. **Visible**: Experience windows are displayed
3. **Hidden**: Experience windows are hidden but state is preserved
4. **Destroyed**: Experience is removed from state manager

### State Persistence

When an experience is hidden:
- Window configurations are saved
- Buffer references are maintained
- Layout structure is preserved
- Window-to-experience mappings are cleared

When an experience is shown:
- Windows are recreated according to saved layout
- Buffers are restored or recreated
- Window configurations are restored
- Mappings are re-established

### Window Cleanup

Windows are cleaned up when:
- Experience is hidden (if configured)
- Experience is destroyed
- Window is manually closed (triggers experience hide)
- Neovim closes

## Hook System

### Hook Execution Order

1. `before_create` - Before experience is registered
2. `after_create` - After experience is registered
3. `before_show` - Before windows are created
4. `after_show` - After windows are created and focused
5. `on_focus` - When any window in experience gains focus
6. `on_buffer_enter` - When entering any buffer in experience
7. `before_hide` - Before windows are hidden
8. `after_hide` - After windows are hidden
9. `before_destroy` - Before experience is removed
10. `after_destroy` - After experience is removed

### Hook Context

Hooks receive the Experience object, which includes:
- `id`: Experience identifier
- `state`: Current state
- `layout`: Layout definition
- `windows`: Array of window IDs
- `buffers`: Array of buffer IDs
- `metadata`: Custom metadata
- `api`: Experience API methods

### Example Hook Usage

```lua
local experience = tfling.create({
  id = "debugger",
  layout = { ... },
  hooks = {
    before_show = function(exp)
      -- Set up debugger state
      exp.metadata.debugger_attached = false
    end,
    after_show = function(exp)
      -- Attach debugger
      local main_window = exp.windows[1]
      vim.api.nvim_win_call(main_window, function()
        -- Run debugger attach command
        vim.cmd("DebuggerStart")
        exp.metadata.debugger_attached = true
      end)
    end,
    before_hide = function(exp)
      -- Detach debugger before hiding
      if exp.metadata.debugger_attached then
        vim.cmd("DebuggerStop")
      end
    end,
    on_focus = function(exp, win_id)
      -- Update statusline when experience gains focus
      vim.g.current_experience = exp.id
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

### Dynamic Layouts

Layouts can be modified at runtime:

```lua
local experience = tfling.create({ id = "tool", layout = initial_layout })

-- Modify layout
experience:layout({
  type = "split",
  direction = "horizontal",
  ...
})

-- Reapply layout
experience:apply_layout()
```

### Window Operations

Individual windows within an experience can be manipulated:

```lua
local experience = tfling.get("my-tool")

-- Resize a specific window
experience:resize_window(win_id, { width = "+10%", height = "+5%" })

-- Reposition a floating window
experience:reposition_window(win_id, { position = "bottom-right" })

-- Focus a specific window
experience:focus_window(win_id)

-- Close a specific window (hides experience if last window)
experience:close_window(win_id)
```

## Migration from v1

### Compatibility Layer

A compatibility layer allows v1 code to work with minimal changes:

```lua
-- v1 API
require("tfling").term({
  name = "my-term",
  cmd = "htop",
  win = { type = "floating", position = "center" },
})

-- v2 compatibility
require("tfling.v1_compat").term({
  name = "my-term",
  cmd = "htop",
  win = { type = "floating", position = "center" },
})
```

### Migration Guide

1. Replace `tfling.term()` with `tfling.create()`
2. Convert window configs to Layout format
3. Move setup hooks to Experience hooks
4. Update state queries to use new API

## Implementation Plan

### Phase 1: Core State Management
- [ ] StateManager implementation
- [ ] Experience lifecycle
- [ ] Basic show/hide functionality

### Phase 2: Layout Engine
- [ ] Layout parser
- [ ] Window creation (splits, tabs, floats)
- [ ] Window restoration

### Phase 3: Hook System
- [ ] Hook registration
- [ ] Hook execution
- [ ] Hook context

### Phase 4: Advanced Features
- [ ] Experience groups
- [ ] Dynamic layouts
- [ ] Window operations

### Phase 5: Compatibility & Polish
- [ ] v1 compatibility layer
- [ ] Documentation
- [ ] Examples

## File Structure

```
lua/tfling/v2/
  init.lua              -- Main entry point
  state.lua             -- StateManager
  experience.lua        -- Experience class
  layout.lua            -- Layout engine
  hooks.lua             -- Hook system
  window.lua            -- Window registry
  buffer.lua            -- Buffer management
  builder.lua           -- Layout builder API
  groups.lua            -- Experience groups
  compat/
    v1.lua              -- v1 compatibility layer
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

### Layout Builder

- `tfling.layout()` - Create layout builder
- `builder:split(direction, config)` - Add split
- `builder:tab(config)` - Add tab
- `builder:float(config)` - Add float
- `builder:buffer(spec)` - Set buffer
- `builder:end_split()` - End split context
- `builder:build()` - Build layout

### Experience Methods

- `experience:show()` - Show experience
- `experience:hide()` - Hide experience
- `experience:toggle()` - Toggle experience
- `experience:destroy()` - Destroy experience
- `experience:layout(new_layout)` - Update layout
- `experience:apply_layout()` - Reapply layout
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
