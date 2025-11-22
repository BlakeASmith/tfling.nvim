# Tfling v2 Design Summary

## Quick Overview

Tfling v2 is a **state management library** for Neovim that provides a flexible, low-level API for creating toggleable screen experiences. It abstracts window/tab/split management into logical groupings called "Experiences" that can be shown, hidden, and managed as cohesive units.

## Key Concepts

### Experience
A logical grouping of windows/tabs/splits that form a cohesive user experience. Experiences can be toggled on/off as a unit.

### Layout
Defines the structure of windows, tabs, and splits. Supports nested structures and combinations of float, split, tab, and container types.

### Buffer Specification
Describes what content to display: terminal, file, scratch buffer, or function-generated content.

### Hooks
Lifecycle and event hooks allow plugin developers to inject custom behavior at key points (before_show, after_show, on_focus, etc.).

## Core API

```lua
local tfling = require("tfling.v2")

-- Create an experience
local exp = tfling.create({
  id = "my-tool",
  layout = { ... },
  hooks = { ... },
})

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
- Support for floats, splits, tabs, and containers
- Nested layouts
- Buffer management (terminal, file, scratch, function)
- Lifecycle hooks
- Window restoration

### ✅ Advanced Features
- Experience groups
- Dependency management
- Dynamic layout modification
- Window operations (resize, reposition)
- Layout builder API
- v1 compatibility layer

## Architecture

```
StateManager (tracks all experiences)
    ↓
Experience (logical grouping)
    ↓
Layout (defines structure)
    ↓
Window/Buffer (actual Neovim elements)
```

## Implementation Phases

1. **Phase 1**: Core state management (2-3 weeks)
2. **Phase 2**: Layout engine (3-4 weeks)
3. **Phase 3**: Buffer management (2-3 weeks)
4. **Phase 4**: Hook system (1-2 weeks)
5. **Phase 5**: Advanced features (3-4 weeks)
6. **Phase 6**: Compatibility layer (1-2 weeks)
7. **Phase 7**: Polish & optimization (2-3 weeks)

**Total**: ~3.5-5 months

## Example Usage

### Simple Floating Terminal

```lua
local term = tfling.create({
  id = "quick-term",
  layout = {
    type = "float",
    config = { width = "80%", height = "60%", position = "center" },
    buffer = { type = "terminal", source = "bash" },
  },
})
term:toggle()
```

### Complex Multi-Window Layout

```lua
local monitoring = tfling.create({
  id = "monitoring",
  layout = {
    type = "container",
    children = {
      { type = "float", config = {...}, buffer = {...} },  -- CPU
      { type = "float", config = {...}, buffer = {...} },  -- I/O
      { type = "float", config = {...}, buffer = {...} },  -- Network
    },
  },
})
```

## Design Principles

1. **State Management First**: Core is about managing UI state
2. **Low-Level API**: Provides primitives for composition
3. **Extensible**: Hook system for custom behavior
4. **Flexible**: Supports any layout combination
5. **Backward Compatible**: v1 compatibility layer

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
- ✅ Layouts are declarative (not imperative)
- ✅ Hooks provide extensibility (not inheritance)
- ✅ State is centralized (not distributed)

## File Structure

```
lua/tfling/v2/
  init.lua              -- Main API
  state.lua             -- StateManager
  experience.lua        -- Experience class
  layout.lua            -- Layout engine
  window.lua            -- Window management
  buffer.lua            -- Buffer management
  hooks.lua             -- Hook system
  geometry.lua          -- Geometry calculations
  groups.lua            -- Experience groups
  builder.lua           -- Layout builder
  compat/v1.lua         -- v1 compatibility
```

## Success Metrics

- ✅ Can create complex multi-window experiences
- ✅ Experiences toggle cleanly
- ✅ Layouts restore correctly
- ✅ Hooks execute reliably
- ✅ Performance is acceptable
- ✅ API is intuitive
- ✅ Documentation is complete

---

**Status**: Design phase complete. Ready for implementation.
