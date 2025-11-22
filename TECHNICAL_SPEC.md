# Tfling v2 Technical Specification

## Data Structures

### Experience

```lua
Experience = {
  id = string,                    -- Unique identifier
  state = "created" | "visible" | "hidden" | "destroyed",
  metadata = {},                   -- Arbitrary data storage
  hooks = Hooks,                  -- Lifecycle hooks
  
  -- Registered elements
  windows = {},                   -- Array of window IDs
  buffers = {},                   -- Array of buffer IDs
  tabs = {},                      -- Array of tabpage IDs
  
  -- Saved state for restoration
  window_configs = {},            -- Map<win_id, WindowConfig>
  buffer_states = {},             -- Map<buf_id, BufferState>
  tab_states = {},                -- Map<tab_id, TabState>
  
  -- Registration options
  window_options = {},            -- Map<win_id, RegistrationOptions>
  buffer_options = {},            -- Map<buf_id, RegistrationOptions>
  tab_options = {},               -- Map<tab_id, RegistrationOptions>
  
  -- Dependencies
  depends_on = {},                -- Array of experience IDs
  dependents = {},                -- Array of experience IDs (computed)
  
  -- Timestamps
  created_at = number,
  last_shown_at = number,
  last_hidden_at = number,
}
```

### WindowConfig

Saved window configuration for restoration:

```lua
WindowConfig = {
  win_id = number,
  config = table,                 -- Result of nvim_win_get_config()
  buffer_id = number,             -- Buffer displayed in window
  cursor_position = { row = number, col = number },
  view_state = {
    topline = number,             -- First visible line
    leftcol = number,            -- First visible column
    skipcol = number,            -- Skip columns
  },
  window_options = table,        -- Saved window-local options
}
```

### BufferState

Saved buffer state:

```lua
BufferState = {
  buffer_id = number,
  filetype = string,
  buftype = string,
  modified = boolean,
  readonly = boolean,
  -- Other buffer state as needed
}
```

### TabState

Saved tabpage state:

```lua
TabState = {
  tab_id = number,
  current_window = number,       -- Active window in tab
  windows = {},                   -- Windows in tab
}
```

### RegistrationOptions

```lua
RegistrationOptions = {
  -- Window options
  save_config = true,            -- Save window config for restoration
  restore_on_show = true,        -- Restore window config when showing
  close_on_hide = false,         -- Close window when hiding
  close_on_destroy = true,       -- Close window when destroying
  
  -- Buffer options
  persistent = true,             -- Keep buffer when hiding
  delete_on_destroy = false,     -- Delete buffer when destroying
  
  -- Tab options
  close_on_hide = false,         -- Close tab when hiding
  close_on_destroy = true,       -- Close tab when destroying
}
```

### Hooks

```lua
Hooks = {
  before_create = function(experience: Experience): nil | false,
  after_create = function(experience: Experience): nil,
  before_show = function(experience: Experience): nil | false,
  after_show = function(experience: Experience): nil,
  before_hide = function(experience: Experience): nil | false,
  after_hide = function(experience: Experience): nil,
  before_destroy = function(experience: Experience): nil | false,
  after_destroy = function(experience: Experience): nil,
  on_window_registered = function(experience: Experience, window_id: number): nil,
  on_buffer_registered = function(experience: Experience, buffer_id: number): nil,
  on_tab_registered = function(experience: Experience, tab_id: number): nil,
  on_window_closed = function(experience: Experience, window_id: number): nil,
  on_buffer_deleted = function(experience: Experience, buffer_id: number): nil,
  on_tab_closed = function(experience: Experience, tab_id: number): nil,
}
```

### StateManager

```lua
StateManager = {
  experiences = {},               -- Map<id, Experience>
  active_experiences = {},        -- Set<id>
  window_to_experience = {},      -- Map<window_id, experience_id>
  buffer_to_experience = {},      -- Map<buffer_id, experience_id>
  tab_to_experience = {},         -- Map<tab_id, experience_id>
  
  -- Event handlers
  on_experience_created = function(experience),
  on_experience_shown = function(experience),
  on_experience_hidden = function(experience),
  on_experience_destroyed = function(experience),
}
```

## Algorithms

### Experience Creation

```lua
function create_experience(opts)
  -- 1. Validate options
  assert(opts.id, "Experience ID required")
  
  -- 2. Check if already exists
  if state_manager.experiences[opts.id] then
    error("Experience already exists: " .. opts.id)
  end
  
  -- 3. Create experience object
  local experience = {
    id = opts.id,
    state = "created",
    metadata = opts.metadata or {},
    hooks = opts.hooks or {},
    windows = {},
    buffers = {},
    tabs = {},
    window_configs = {},
    buffer_states = {},
    tab_states = {},
    window_options = {},
    buffer_options = {},
    tab_options = {},
    depends_on = opts.depends_on or {},
    dependents = {},
    created_at = vim.loop.now(),
  }
  
  -- 4. Execute before_create hook
  if experience.hooks.before_create then
    local result = experience.hooks.before_create(experience)
    if result == false then
      return nil, "Creation cancelled by hook"
    end
  end
  
  -- 5. Register with state manager
  state_manager.experiences[opts.id] = experience
  
  -- 6. Build dependency graph
  build_dependency_graph(experience)
  
  -- 7. Execute after_create hook
  if experience.hooks.after_create then
    experience.hooks.after_create(experience)
  end
  
  -- 8. Emit event
  state_manager.on_experience_created(experience)
  
  return experience
end
```

### Window Registration

```lua
function register_window(experience, win_id, options)
  options = options or {}
  
  -- 1. Validate window
  if not vim.api.nvim_win_is_valid(win_id) then
    error("Invalid window ID: " .. win_id)
  end
  
  -- 2. Check if already registered
  if vim.tbl_contains(experience.windows, win_id) then
    return false, "Window already registered"
  end
  
  -- 3. Save current window config if requested
  if options.save_config ~= false then
    experience.window_configs[win_id] = save_window_config(win_id)
  end
  
  -- 4. Store options
  experience.window_options[win_id] = vim.tbl_extend("force", {
    save_config = true,
    restore_on_show = true,
    close_on_hide = false,
    close_on_destroy = true,
  }, options)
  
  -- 5. Register window
  table.insert(experience.windows, win_id)
  state_manager.window_to_experience[win_id] = experience.id
  
  -- 6. Execute hook
  if experience.hooks.on_window_registered then
    experience.hooks.on_window_registered(experience, win_id)
  end
  
  return true
end

function save_window_config(win_id)
  local config = vim.api.nvim_win_get_config(win_id)
  local buf_id = vim.api.nvim_win_get_buf(win_id)
  local cursor = vim.api.nvim_win_get_cursor(win_id)
  
  -- Get view state
  local view_state = {
    topline = vim.fn.line("w0"),
    leftcol = vim.fn.winsaveview().leftcol,
    skipcol = vim.fn.winsaveview().skipcol,
  }
  
  -- Get window options (save important ones)
  local win_opts = {}
  for opt_name, _ in pairs(important_window_options) do
    win_opts[opt_name] = vim.wo[win_id][opt_name]
  end
  
  return {
    win_id = win_id,
    config = config,
    buffer_id = buf_id,
    cursor_position = { row = cursor[1], col = cursor[2] },
    view_state = view_state,
    window_options = win_opts,
  }
end
```

### Buffer Registration

```lua
function register_buffer(experience, buf_id, options)
  options = options or {}
  
  -- 1. Validate buffer
  if not vim.api.nvim_buf_is_valid(buf_id) then
    error("Invalid buffer ID: " .. buf_id)
  end
  
  -- 2. Check if already registered
  if vim.tbl_contains(experience.buffers, buf_id) then
    return false, "Buffer already registered"
  end
  
  -- 3. Save buffer state if requested
  if options.persistent then
    experience.buffer_states[buf_id] = save_buffer_state(buf_id)
  end
  
  -- 4. Store options
  experience.buffer_options[buf_id] = vim.tbl_extend("force", {
    persistent = true,
    delete_on_destroy = false,
  }, options)
  
  -- 5. Register buffer
  table.insert(experience.buffers, buf_id)
  state_manager.buffer_to_experience[buf_id] = experience.id
  
  -- 6. Execute hook
  if experience.hooks.on_buffer_registered then
    experience.hooks.on_buffer_registered(experience, buf_id)
  end
  
  return true
end

function save_buffer_state(buf_id)
  return {
    buffer_id = buf_id,
    filetype = vim.bo[buf_id].filetype,
    buftype = vim.bo[buf_id].buftype,
    modified = vim.bo[buf_id].modified,
    readonly = vim.bo[buf_id].readonly,
  }
end
```

### Tab Registration

```lua
function register_tab(experience, tab_id, options)
  options = options or {}
  
  -- 1. Validate tab
  if not vim.api.nvim_tabpage_is_valid(tab_id) then
    error("Invalid tabpage ID: " .. tab_id)
  end
  
  -- 2. Check if already registered
  if vim.tbl_contains(experience.tabs, tab_id) then
    return false, "Tab already registered"
  end
  
  -- 3. Save tab state
  experience.tab_states[tab_id] = save_tab_state(tab_id)
  
  -- 4. Store options
  experience.tab_options[tab_id] = vim.tbl_extend("force", {
    close_on_hide = false,
    close_on_destroy = true,
  }, options)
  
  -- 5. Register tab
  table.insert(experience.tabs, tab_id)
  state_manager.tab_to_experience[tab_id] = experience.id
  
  -- 6. Execute hook
  if experience.hooks.on_tab_registered then
    experience.hooks.on_tab_registered(experience, tab_id)
  end
  
  return true
end

function save_tab_state(tab_id)
  local current_win = vim.api.nvim_tabpage_get_win(tab_id)
  local windows = vim.api.nvim_tabpage_list_wins(tab_id)
  
  return {
    tab_id = tab_id,
    current_window = current_win,
    windows = windows,
  }
end
```

### Experience Show

```lua
function show_experience(id)
  local experience = state_manager.experiences[id]
  if not experience then
    error("Experience not found: " .. id)
  end
  
  if experience.state == "visible" then
    -- Already visible, just focus
    focus_experience(experience)
    return true
  end
  
  -- 1. Execute before_show hook
  if experience.hooks.before_show then
    local result = experience.hooks.before_show(experience)
    if result == false then
      return false, "Show cancelled by hook"
    end
  end
  
  -- 2. Show dependencies first
  for _, dep_id in ipairs(experience.depends_on) do
    show_experience(dep_id)
  end
  
  -- 3. Restore windows
  restore_windows(experience)
  
  -- 4. Restore tabs
  restore_tabs(experience)
  
  -- 5. Update state
  experience.state = "visible"
  experience.last_shown_at = vim.loop.now()
  table.insert(state_manager.active_experiences, id)
  
  -- 6. Focus primary window
  focus_experience(experience)
  
  -- 7. Execute after_show hook
  if experience.hooks.after_show then
    experience.hooks.after_show(experience)
  end
  
  -- 8. Emit event
  state_manager.on_experience_shown(experience)
  
  return true
end

function restore_windows(experience)
  local restored_windows = {}
  
  for _, win_id in ipairs(experience.windows) do
    local options = experience.window_options[win_id] or {}
    
    if vim.api.nvim_win_is_valid(win_id) then
      -- Window exists, restore config
      if options.restore_on_show ~= false then
        local saved_config = experience.window_configs[win_id]
        if saved_config then
          restore_window_config(win_id, saved_config)
        end
      end
      table.insert(restored_windows, win_id)
    else
      -- Window was closed, remove from registry
      -- Plugin should recreate via hook
      remove_window_from_registry(experience, win_id)
    end
  end
  
  -- Update windows list (remove invalid windows)
  experience.windows = restored_windows
end

function restore_window_config(win_id, saved_config)
  -- Restore window config
  if saved_config.config then
    vim.api.nvim_win_set_config(win_id, saved_config.config)
  end
  
  -- Restore buffer
  if saved_config.buffer_id and vim.api.nvim_buf_is_valid(saved_config.buffer_id) then
    vim.api.nvim_win_set_buf(win_id, saved_config.buffer_id)
  end
  
  -- Restore cursor position
  if saved_config.cursor_position then
    vim.api.nvim_win_set_cursor(win_id, {
      saved_config.cursor_position.row,
      saved_config.cursor_position.col,
    })
  end
  
  -- Restore view state
  if saved_config.view_state then
    vim.fn.winrestview({
      topline = saved_config.view_state.topline,
      leftcol = saved_config.view_state.leftcol,
      skipcol = saved_config.view_state.skipcol,
    })
  end
  
  -- Restore window options
  if saved_config.window_options then
    for opt_name, opt_value in pairs(saved_config.window_options) do
      vim.wo[win_id][opt_name] = opt_value
    end
  end
end

function restore_tabs(experience)
  for _, tab_id in ipairs(experience.tabs) do
    if vim.api.nvim_tabpage_is_valid(tab_id) then
      -- Switch to tab
      vim.api.nvim_set_current_tabpage(tab_id)
      
      -- Restore tab state
      local saved_state = experience.tab_states[tab_id]
      if saved_state and saved_state.current_window then
        if vim.api.nvim_win_is_valid(saved_state.current_window) then
          vim.api.nvim_set_current_win(saved_state.current_window)
        end
      end
    else
      -- Tab was closed, remove from registry
      remove_tab_from_registry(experience, tab_id)
    end
  end
end

function focus_experience(experience)
  -- Focus first valid window
  for _, win_id in ipairs(experience.windows) do
    if vim.api.nvim_win_is_valid(win_id) then
      vim.api.nvim_set_current_win(win_id)
      return
    end
  end
  
  -- If no windows, focus first tab
  for _, tab_id in ipairs(experience.tabs) do
    if vim.api.nvim_tabpage_is_valid(tab_id) then
      vim.api.nvim_set_current_tabpage(tab_id)
      return
    end
  end
end
```

### Experience Hide

```lua
function hide_experience(id)
  local experience = state_manager.experiences[id]
  if not experience then
    error("Experience not found: " .. id)
  end
  
  if experience.state == "hidden" then
    return true
  end
  
  -- 1. Execute before_hide hook
  if experience.hooks.before_hide then
    local result = experience.hooks.before_hide(experience)
    if result == false then
      return false, "Hide cancelled by hook"
    end
  end
  
  -- 2. Hide dependents first
  for _, dep_id in ipairs(experience.dependents) do
    hide_experience(dep_id)
  end
  
  -- 3. Save window configurations
  save_window_configs(experience)
  
  -- 4. Save tab states
  save_tab_states(experience)
  
  -- 5. Close windows if configured
  close_windows_if_needed(experience)
  
  -- 6. Close tabs if configured
  close_tabs_if_needed(experience)
  
  -- 7. Update state
  experience.state = "hidden"
  experience.last_hidden_at = vim.loop.now()
  
  -- Remove from active experiences
  for i, active_id in ipairs(state_manager.active_experiences) do
    if active_id == id then
      table.remove(state_manager.active_experiences, i)
      break
    end
  end
  
  -- 8. Execute after_hide hook
  if experience.hooks.after_hide then
    experience.hooks.after_hide(experience)
  end
  
  -- 9. Emit event
  state_manager.on_experience_hidden(experience)
  
  return true
end

function save_window_configs(experience)
  for _, win_id in ipairs(experience.windows) do
    if vim.api.nvim_win_is_valid(win_id) then
      local options = experience.window_options[win_id] or {}
      if options.save_config ~= false then
        experience.window_configs[win_id] = save_window_config(win_id)
      end
    end
  end
end

function close_windows_if_needed(experience)
  local kept_windows = {}
  
  for _, win_id in ipairs(experience.windows) do
    if vim.api.nvim_win_is_valid(win_id) then
      local options = experience.window_options[win_id] or {}
      if options.close_on_hide then
        vim.api.nvim_win_close(win_id, true)
      else
        table.insert(kept_windows, win_id)
      end
    end
  end
  
  experience.windows = kept_windows
end

function close_tabs_if_needed(experience)
  local kept_tabs = {}
  
  for _, tab_id in ipairs(experience.tabs) do
    if vim.api.nvim_tabpage_is_valid(tab_id) then
      local options = experience.tab_options[tab_id] or {}
      if options.close_on_hide then
        vim.api.nvim_tabpage_close(tab_id, true)
      else
        table.insert(kept_tabs, tab_id)
      end
    end
  end
  
  experience.tabs = kept_tabs
end
```

### Window Unregistration

```lua
function unregister_window(experience, win_id)
  -- Remove from windows list
  for i, w_id in ipairs(experience.windows) do
    if w_id == win_id then
      table.remove(experience.windows, i)
      break
    end
  end
  
  -- Remove saved config
  experience.window_configs[win_id] = nil
  experience.window_options[win_id] = nil
  
  -- Remove from state manager mapping
  state_manager.window_to_experience[win_id] = nil
  
  return true
end
```

### Window Event Handling

```lua
-- Set up autocommands for window events
function setup_window_autocommands()
  -- Window closed
  vim.api.nvim_create_autocmd("WinClosed", {
    callback = function(event)
      local win_id = tonumber(event.match)
      local exp_id = state_manager.window_to_experience[win_id]
      
      if exp_id then
        local experience = state_manager.experiences[exp_id]
        if experience then
          -- Remove window from experience
          unregister_window(experience, win_id)
          
          -- Execute hook
          if experience.hooks.on_window_closed then
            experience.hooks.on_window_closed(experience, win_id)
          end
        end
        
        state_manager.window_to_experience[win_id] = nil
      end
    end,
  })
  
  -- Buffer deleted
  vim.api.nvim_create_autocmd("BufDelete", {
    callback = function(event)
      local buf_id = event.buf
      local exp_id = state_manager.buffer_to_experience[buf_id]
      
      if exp_id then
        local experience = state_manager.experiences[exp_id]
        if experience then
          -- Remove buffer from experience
          unregister_buffer(experience, buf_id)
          
          -- Execute hook
          if experience.hooks.on_buffer_deleted then
            experience.hooks.on_buffer_deleted(experience, buf_id)
          end
        end
        
        state_manager.buffer_to_experience[buf_id] = nil
      end
    end,
  })
  
  -- Tab closed
  vim.api.nvim_create_autocmd("TabClosed", {
    callback = function(event)
      local tab_id = tonumber(event.match)
      local exp_id = state_manager.tab_to_experience[tab_id]
      
      if exp_id then
        local experience = state_manager.experiences[exp_id]
        if experience then
          -- Remove tab from experience
          unregister_tab(experience, tab_id)
          
          -- Execute hook
          if experience.hooks.on_tab_closed then
            experience.hooks.on_tab_closed(experience, tab_id)
          end
        end
        
        state_manager.tab_to_experience[tab_id] = nil
      end
    end,
  })
end
```

## Performance Considerations

### Window Validation

- Cache window validity checks
- Batch validation operations
- Lazy validation on show/hide

### State Lookup

- Use hash tables for O(1) lookups
- Cache frequently accessed data
- Minimize state manager queries

### Memory Management

- Clean up invalid window/buffer/tab references
- Limit saved configs for hidden experiences
- Allow config cleanup for old experiences

## Error Handling

### Validation

- Validate window/buffer/tab IDs before registration
- Check for circular dependencies
- Verify elements exist before operations

### Recovery

- Handle invalid window/buffer/tab IDs gracefully
- Recover from failed hook execution
- Restore state on errors
- Log errors for debugging

## Testing Strategy

### Unit Tests

- StateManager operations
- Registration/unregistration
- Window config saving/restoration
- Dependency graph building

### Integration Tests

- Experience lifecycle
- Window restoration
- Hook execution
- Group operations

### E2E Tests

- Multi-window experiences
- Multi-experience interactions
- Error recovery
- Performance benchmarks
