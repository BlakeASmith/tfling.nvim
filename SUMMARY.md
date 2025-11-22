# Tfling v2 Design Summary

## Quick Overview

Tfling v2 is a **state management library** for Neovim that provides a flexible, low-level API for creating toggleable screen experiences. It abstracts window/tab/split management into logical groupings called "Experiences" that can be shown, hidden, and managed as cohesive units.

## Key Concepts

### Experience
A logical grouping of windows/tabs/splits that form a cohesive user experience. Experiences can be toggled on/off as a unit. Acts as a registry for UI elements.

### Registration
UI elements (windows, buffers, tabs) are registered with experiences. Tfling manages their lifecycle but doesn't create them.

### Lifecycle Management
Show/hide/toggle operations that save and restore window/buffer/tab state.

### Hooks
Lifecycle and event hooks allow plugin developers to inject custom behavior at key points (before_show, after_show, on_focus, etc.).

## Core API

```lua
local tfling = require("tfling.v2")

-- Create an experience
local exp = tfling.create({
  id = "my-tool",
  hooks = { ... },
})

-- Plugin creates window/buffer
local buf = vim.api.nvim_create_buf(true, true)
local win = vim.api.nvim_open_win(buf, true, { ... })

-- Register with Tfling
exp:register_window(win)
exp:register_buffer(buf)

-- Control the experience
exp:show()
exp:hide()
exp:toggle()
exp:destroy()
```

## Design Documents

1. **DESIGN.md** - High-level architecture, concepts, and API design
2. **TECHNICAL_SPEC.md** - Detailed data structures, algorithms, and implementation details
3. **EXAMPLES.md** - Practical usage examples and real-world scenarios
4. **ROADMAP.md** - Implementation plan with phases and timelines

## Key Features

### ✅ Core Features
- State management for experiences
- Window/buffer/tab registration
- Lifecycle management (show/hide/toggle)
- State saving and restoration
- Lifecycle hooks
- Window restoration

### ✅ Advanced Features
- Experience groups
- Dependency management
- Window operations (resize, reposition)
- Bulk registration

## Architecture

```
StateManager (tracks all experiences)
    ↓
Experience (logical grouping / registry)
    ↓
Registered Elements (windows/buffers/tabs)
    ↓
Lifecycle Management (show/hide/toggle)
```

## Implementation Phases

1. **Phase 1**: Core state management (2-3 weeks)
2. **Phase 2**: Registration system (2-3 weeks)
3. **Phase 3**: Lifecycle management (2-3 weeks)
4. **Phase 4**: Hook system (1-2 weeks)
5. **Phase 5**: Window operations (1-2 weeks)
6. **Phase 6**: Advanced features (2-3 weeks)
7. **Phase 7**: Polish & optimization (2-3 weeks)

**Total**: ~2.5-4 months

## Example Usage

### Simple Floating Window

```lua
local tfling = require("tfling.v2")

-- Create experience
local exp = tfling.create({ id = "quick-tool" })

-- Plugin creates window
local buf = vim.api.nvim_create_buf(true, true)
local win = vim.api.nvim_open_win(buf, true, {
  relative = "editor",
  width = 50,
  height = 10,
  row = 10,
  col = 30,
})

-- Register with Tfling
exp:register_window(win)
exp:register_buffer(buf)

-- Toggle it
exp:toggle()
```

### Multi-Window Experience

```lua
local exp = tfling.create({ id = "monitoring" })

-- Create and register multiple windows
local win1 = create_cpu_window()
local win2 = create_io_window()
local win3 = create_network_window()

exp:register_window(win1)
exp:register_window(win2)
exp:register_window(win3)

exp:toggle()
```

## Design Principles

1. **State Management Only**: Focuses on grouping and lifecycle, not creation
2. **Dynamic Registration**: UI elements registered, not created by Tfling
3. **Separation of Concerns**: Plugins create, Tfling manages
4. **Low-Level API**: Provides primitives for registration and lifecycle
5. **Extensible**: Hook system for custom behavior

## Next Steps

1. Review design documents
2. Set up project structure
3. Begin Phase 1 implementation
4. Set up testing infrastructure

## Questions & Considerations

### Open Questions
- Should experiences support "minimized" state (iconified)?
- How to handle window focus conflicts?
- Should there be a "workspace" concept above experiences?
- How to handle Neovim tab pages vs experience "tabs"?

### Design Decisions
- ✅ Experiences are the primary abstraction (not windows)
- ✅ Registration is dynamic (not declarative)
- ✅ Hooks provide extensibility (not inheritance)
- ✅ State is centralized (not distributed)
- ✅ Plugins create, Tfling manages

## File Structure

```
lua/tfling/v2/
  init.lua              -- Main API
  state.lua             -- StateManager
  experience.lua        -- Experience class
  registry.lua          -- Window/buffer/tab registration
  lifecycle.lua         -- Show/hide/toggle lifecycle
  hooks.lua             -- Hook system
  groups.lua            -- Experience groups
  util.lua              -- Utility functions
```

## Success Metrics

- ✅ Can register and manage multiple windows/buffers/tabs
- ✅ Experiences toggle cleanly with state restoration
- ✅ Registration model works smoothly
- ✅ Hooks execute reliably
- ✅ Performance is acceptable
- ✅ API is intuitive
- ✅ Documentation is complete

---

**Status**: Design phase complete. Ready for implementation.
