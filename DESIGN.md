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

## Implementing Current Term Functionality with v2

This section outlines how the current `tfling.term()` and `tfling.buff()` functionality will be implemented using the v2 core utilities. The term functionality will be built as a **high-level convenience layer** on top of the v2 state management primitives.

### Overview

The current term functionality provides:
- Terminal buffer creation and management (`termopen()`)
- Window creation (floating and split windows)
- Lifecycle management (toggle/show/hide)
- Session persistence (tmux/abduco integration)
- Window operations (resize, reposition)
- Buffer navigation (next/prev, list, goto)
- Setup hooks and global callbacks
- Command sending to terminals

All of this will be implemented using v2 experiences, registration, and lifecycle hooks, with additional term-specific utilities layered on top.

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│  High-Level API (tfling.term / tfling.buff)            │
│  - Terminal creation helpers                            │
│  - Window geometry calculation                          │
│  - Session management (tmux/abduco)                     │
│  - Buffer navigation                                    │
│  - Setup hooks & callbacks                              │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  v2 Core Utilities                                      │
│  - Experience creation & management                     │
│  - Window/tab registration                              │
│  - Lifecycle hooks (onShow/onHide/onDestroy)           │
│  - State saving & restoration                          │
│  - Window operations (resize/reposition/focus)          │
└─────────────────────────────────────────────────────────┘
```

### Core Mapping

Each terminal/buffer instance maps to a **single Experience**:

```lua
TerminalInstance {
  experience: Experience        -- v2 experience managing this terminal
  bufnr: number                 -- Terminal/buffer ID
  win_id: number                -- Window ID (registered with experience)
  job_id: number?               -- Terminal job ID (if terminal)
  name: string                  -- Unique name (used as experience ID)
  cmd: string?                  -- Command to run
  config: TermConfig            -- Window config, session settings, etc.
  metadata: table               -- Stored in experience.metadata
}
```

### Implementation Plan

#### Phase 1: Basic Term Experience Creation

**Goal**: Create terminal experiences using v2 core

**Implementation**:
1. Create a term experience factory function
2. Use v2 `create()` to instantiate experiences
3. Store term-specific metadata in `experience.metadata`
4. Register windows when created

```lua
-- lua/tfling/term/v2.lua

local v2 = require("tfling.v2")
local geometry = require("tfling.geometry")
local defaults = require("tfling.defaults")

local function create_term_experience(opts)
  -- Create v2 experience
  local exp = v2.create({
    id = opts.name,
    metadata = {
      type = opts.cmd and "terminal" or "buffer",
      cmd = opts.cmd,
      init = opts.init,
      win_config = opts.win,
      session_provider = opts.tmux and "tmux" or (opts.abduco and "abduco" or nil),
    },
    hooks = {
      onShow = function(exp)
        -- Window creation logic (see Phase 2)
      end,
      onHide = function(exp)
        -- Window cleanup logic
      end,
    },
  })
  
  return exp
end
```

**Key Points**:
- Each term instance = one experience
- Experience ID = term name
- Term-specific data stored in `metadata`
- Window registration happens in `onShow` hook

#### Phase 2: Window Creation & Registration

**Goal**: Create and register windows using v2 registration API

**Implementation**:
1. Create buffer in `onShow` hook (if not exists)
2. Create window using geometry utilities
3. Register window with experience
4. Handle both floating and split windows

```lua
hooks = {
  onShow = function(exp)
    local metadata = exp.metadata
    
    -- Get or create buffer
    local bufnr = metadata.bufnr
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
      bufnr = vim.api.nvim_create_buf(true, true)
      vim.bo[bufnr].bufhidden = "hide"
      vim.bo[bufnr].filetype = "tfling"
      metadata.bufnr = bufnr
      
      -- Initialize buffer (cmd, init, etc.)
      if metadata.cmd then
        -- Handle session providers
        local actual_cmd = metadata.cmd
        if metadata.session_provider then
          actual_cmd = build_session_cmd(metadata)
        end
        
        -- Start terminal
        local job_id = vim.fn.termopen(actual_cmd, {
          on_exit = function()
            -- Cleanup on exit
            exp.metadata.job_id = nil
          end,
        })
        metadata.job_id = job_id
        vim.cmd("startinsert")
      elseif metadata.init then
        -- Handle init function/string
        handle_init(bufnr, metadata.init, exp)
      end
    end
    
    -- Create window if not already registered
    if #exp:get_windows() == 0 then
      local win_config = defaults.apply_win_defaults(metadata.win_config)
      local win_opts = geometry.floating(win_config)  -- or split logic
      local win_id = vim.api.nvim_open_win(bufnr, true, win_opts)
      
      -- Register window with experience
      exp:register_window(win_id)
      
      -- Setup window options
      setup_window_options(win_id, win_config)
    else
      -- Window already exists, just focus it
      exp:focus_window(exp:get_windows()[1])
    end
  end,
  
  onHide = function(exp)
    -- v2 handles window hiding automatically
    -- But we may want to keep buffer alive
    -- (v2 saves state, so buffer persists)
  end,
}
```

**Key Points**:
- Buffer creation in `onShow` hook (lazy creation)
- Window registration via `exp:register_window()`
- Window state automatically saved/restored by v2
- Buffer persists across hide/show cycles

#### Phase 3: Window Operations

**Goal**: Implement resize and reposition using v2 window operations

**Implementation**:
1. Use v2 `resize_window()` and `reposition_window()` APIs
2. Map current term API to v2 operations
3. Handle both floating and split windows

```lua
-- Term instance methods
function TermInstance:resize(options)
  local win_id = self.experience:get_windows()[1]
  if win_id then
    self.experience:resize_window(win_id, options)
  end
end

function TermInstance:reposition(options)
  local win_id = self.experience:get_windows()[1]
  if win_id then
    self.experience:reposition_window(win_id, options)
  end
end
```

**v2 Window Operations API Enhancement**:
The v2 core needs to support the current term window operation syntax:
- Percentage-based sizing (`"50%"`, `"+5%"`)
- Position-based repositioning (`"top-left"`, `"center"`)
- Relative positioning (`row="+10"`, `col="50%"`)

These will be implemented in v2's `resize_window()` and `reposition_window()` methods.

#### Phase 4: Session Management (tmux/abduco)

**Goal**: Integrate session providers with v2 lifecycle

**Implementation**:
1. Build session commands in `onShow` hook
2. Use existing `tfling.sessions` module
3. Store session info in experience metadata

```lua
local function build_session_cmd(metadata)
  local sessions = require("tfling.sessions")
  local session_name = "tfling-" .. metadata.name
  local cmd_table = vim.split(metadata.cmd, " ")
  
  local provider = metadata.session_provider == "tmux" 
    and sessions.tmux 
    or sessions.abduco
  
  if provider then
    return table.concat(provider.create_or_attach_cmd({
      session_id = session_name,
      cmd = cmd_table,
    }), " ")
  end
  
  return metadata.cmd
end
```

**Key Points**:
- Session command building happens before `termopen()`
- Session state persists independently of Neovim windows
- No special handling needed in `onHide` (sessions persist)

#### Phase 5: Buffer Navigation

**Goal**: Implement buffer list navigation using v2 experience registry

**Implementation**:
1. Maintain ordered list of term experience IDs
2. Use v2 StateManager to query all experiences
3. Filter for term experiences
4. Navigate by showing/hiding experiences

```lua
-- lua/tfling/term/navigation.lua

local v2 = require("tfling.v2")

local buffer_list = {}  -- Ordered list of term names
local current_index = nil

local function get_term_experiences()
  local state = v2.get_state()  -- Access StateManager
  local terms = {}
  
  for id, exp in pairs(state.experiences) do
    if exp.metadata and exp.metadata.type == "terminal" then
      table.insert(terms, { id = id, exp = exp })
    end
  end
  
  return terms
end

function M.next()
  local terms = get_term_experiences()
  if #terms == 0 then return end
  
  -- Hide current
  if current_index and buffer_list[current_index] then
    local exp = v2.get(buffer_list[current_index])
    if exp then exp:hide() end
  end
  
  -- Show next
  current_index = ((current_index or 0) % #buffer_list) + 1
  local exp = v2.get(buffer_list[current_index])
  if exp then exp:show() end
end

function M.prev()
  -- Similar logic, decrementing index
end

function M.goto_buffer(name)
  local exp = v2.get(name)
  if exp then
    exp:show()
    current_index = find_index_in_list(name)
  end
end

function M.list_buffers()
  local terms = get_term_experiences()
  -- Format and display list
end
```

**Key Points**:
- Navigation uses v2 `show()`/`hide()` methods
- StateManager provides registry of all experiences
- Filter experiences by metadata.type
- Maintain separate navigation state (buffer_list, current_index)

#### Phase 6: Setup Hooks & Callbacks

**Goal**: Implement `setup` and `always` callbacks using v2 hooks + autocmds

**Implementation**:
1. `setup` callback: Use BufEnter autocmd (same as current)
2. `always` callback: Global callback for all terms
3. Store callbacks in experience metadata
4. Execute in `onShow` hook or autocmd

```lua
-- In create_term_experience()
local exp = v2.create({
  id = opts.name,
  metadata = {
    -- ... other metadata ...
    setup_callback = opts.setup,
    always_callback = Config.always,  -- Global config
  },
  hooks = {
    onShow = function(exp)
      -- ... window creation ...
      
      -- Setup autocmd for setup callback
      if exp.metadata.setup_callback then
        setup_bufenter_autocmd(exp)
      end
    end,
  },
})

local function setup_bufenter_autocmd(exp)
  local augroup = "tfling." .. exp.id .. ".setup"
  vim.api.nvim_create_augroup(augroup, { clear = true })
  
  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    buffer = exp.metadata.bufnr,
    callback = function()
      local term_details = build_term_details(exp)
      
      -- Call always callback
      if exp.metadata.always_callback then
        exp.metadata.always_callback(term_details)
      end
      
      -- Call setup callback
      if exp.metadata.setup_callback then
        exp.metadata.setup_callback(term_details)
      end
    end,
  })
end

local function build_term_details(exp)
  return {
    job_id = exp.metadata.job_id,
    bufnr = exp.metadata.bufnr,
    win_id = exp:get_windows()[1],
    name = exp.id,
    cmd = exp.metadata.cmd,
    selected_text = exp.metadata.selected_text,
    send = function(cmd)
      send_to_terminal(exp, cmd)
    end,
    win = {
      resize = function(opts)
        exp:resize_window(exp:get_windows()[1], opts)
      end,
      reposition = function(opts)
        exp:reposition_window(exp:get_windows()[1], opts)
      end,
    },
  }
end
```

**Key Points**:
- Callbacks stored in experience metadata
- Autocmds set up in `onShow` hook
- `term_details` object built dynamically from experience state
- Selected text captured before experience creation

#### Phase 7: Command Sending

**Goal**: Implement `send()` functionality for terminals

**Implementation**:
1. Store job_id in experience metadata
2. Use `nvim_chan_send()` with delay
3. Expose via `term_details.send` function

```lua
local function send_to_terminal(exp, command)
  local job_id = exp.metadata.job_id
  if not job_id then return end
  
  local delay = exp.metadata.send_delay or Config.send_delay or 100
  vim.defer_fn(function()
    vim.api.nvim_chan_send(job_id, command)
  end, delay)
end
```

**Key Points**:
- Job ID stored in metadata
- Delay configurable per-term or globally
- Simple wrapper around Neovim API

#### Phase 8: Selected Text Capture

**Goal**: Capture selected text before term operations

**Implementation**:
1. Capture in `term()`/`buff()` entry point
2. Store in experience metadata
3. Expose via `term_details.selected_text`

```lua
function M.term(opts)
  -- Capture selected text BEFORE any operations
  local selected_text = util.get_selected_text()
  
  -- Create experience
  local exp = create_term_experience(opts)
  exp.metadata.selected_text = selected_text
  
  -- Show experience
  exp:toggle({ win = opts.win })
end
```

**Key Points**:
- Capture happens before experience creation
- Stored in metadata for later access
- Available in setup callbacks

### API Design

#### High-Level Term API

```lua
-- Main entry points (unchanged from current API)
require("tfling").term(opts)
require("tfling").buff(opts)

-- Term options (same as current)
opts {
  name: string?              -- Experience ID
  cmd: string?               -- Terminal command
  init: string | function?   -- Buffer initialization
  bufnr: number?             -- Existing buffer
  win: WindowConfig?         -- Window configuration
  tmux: boolean?             -- Use tmux session
  abduco: boolean?           -- Use abduco session
  setup: function?           -- Setup callback
  send_delay: number?        -- Command send delay
}

-- Returned term instance (via callbacks)
term_details {
  job_id: number?
  bufnr: number
  win_id: number
  name: string
  cmd: string?
  selected_text: string?
  send: function(cmd: string)
  win: {
    resize: function(opts)
    reposition: function(opts)
  }
}
```

#### Internal v2 Integration

```lua
-- Term experience structure
Experience {
  id: string                    -- Term name
  state: "hidden" | "visible"
  windows: [win_id]             -- Single window per term
  tabs: []
  metadata: {
    type: "terminal" | "buffer"
    bufnr: number
    win_id: number              -- Same as windows[1]
    job_id: number?             -- Terminal job ID
    cmd: string?
    init: string | function?
    win_config: WindowConfig
    session_provider: "tmux" | "abduco" | nil
    selected_text: string?
    setup_callback: function?
    always_callback: function?
    send_delay: number?
  }
  hooks: {
    onShow: function(exp)        -- Window creation
    onHide: function(exp)        -- Cleanup (optional)
    onDestroy: function(exp)     -- Full cleanup
  }
}
```

### Migration Strategy

#### Backward Compatibility

The high-level API (`tfling.term()`, `tfling.buff()`) will remain **unchanged**. The implementation will switch from the current direct approach to using v2 core utilities, but the external API stays the same.

#### Implementation Steps

1. **Build v2 core first** (Phases 1-6 from main implementation plan)
2. **Create term wrapper layer** (`lua/tfling/term/v2.lua`)
3. **Migrate term functionality incrementally**:
   - Start with basic experience creation
   - Add window creation/registration
   - Add window operations
   - Add session management
   - Add navigation
   - Add callbacks
4. **Maintain feature parity** with current implementation
5. **Test thoroughly** before removing old implementation

#### File Structure

```
lua/tfling/
  v2/                          -- v2 core utilities
    init.lua
    state.lua
    experience.lua
    registry.lua
    lifecycle.lua
    hooks.lua
    groups.lua
    util.lua
  term/                        -- Term-specific implementation
    v2.lua                      -- Main term implementation using v2
    navigation.lua              -- Buffer navigation
    window.lua                  -- Window operations wrapper
    session.lua                 -- Session management
  tfling.lua                    -- Main entry point (uses term/v2)
  defaults.lua                  -- Window defaults (unchanged)
  geometry.lua                  -- Geometry calculations (unchanged)
  sessions.lua                  -- Session providers (unchanged)
  util.lua                      -- Utilities (unchanged)
```

### Benefits of v2 Approach

1. **Separation of Concerns**: Term functionality uses v2 primitives, not custom state management
2. **Consistency**: All toggleable UI uses same underlying system
3. **Extensibility**: Easy to add new term features using v2 hooks
4. **Maintainability**: Less custom code, more reuse of core utilities
5. **Testability**: v2 core can be tested independently
6. **Future-Proof**: New v2 features automatically benefit term functionality

### Open Questions

1. **Window State Persistence**: Should term windows remember exact position/size across sessions, or just buffer state?
   - **Decision**: v2 saves window config, so position/size will persist

2. **Buffer Cleanup**: When should term buffers be deleted?
   - **Decision**: Buffers persist until explicitly destroyed via `exp:destroy()`

3. **Multiple Windows per Term**: Should we support multiple windows for one terminal?
   - **Decision**: Current implementation is single-window, keep that for now

4. **Experience Groups**: Should terms be groupable?
   - **Decision**: Yes, via v2 groups API - terms can be added to groups

5. **Dependencies**: Can terms depend on other experiences?
   - **Decision**: Yes, via v2 dependency system (future enhancement)
