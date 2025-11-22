# Tfling v2 Technical Specification

## Data Structures

### Experience

```lua
Experience = {
  id = string,                    -- Unique identifier
  state = "created" | "visible" | "hidden" | "destroyed",
  layout = Layout,                -- Layout definition
  metadata = {},                   -- Arbitrary data storage
  hooks = Hooks,                  -- Lifecycle hooks
  
  -- Runtime state
  windows = {},                   -- Array of window IDs
  buffers = {},                   -- Array of buffer IDs
  window_configs = {},            -- Saved window configs (for restoration)
  buffer_specs = {},              -- Buffer specifications
  
  -- Dependencies
  depends_on = {},                -- Array of experience IDs
  dependents = {},                -- Array of experience IDs (computed)
  
  -- Timestamps
  created_at = number,
  last_shown_at = number,
  last_hidden_at = number,
}
```

### Layout

```lua
Layout = {
  type = "split" | "tab" | "float" | "container",
  config = LayoutConfig,
  buffer = BufferSpec | nil,
  children = Layout[] | nil,
  
  -- Internal tracking
  window_id = number | nil,       -- Associated window ID
  buffer_id = number | nil,       -- Associated buffer ID
  parent_layout = Layout | nil,   -- Parent layout reference
}
```

### LayoutConfig

```lua
-- For splits
SplitConfig = {
  direction = "horizontal" | "vertical",
  size = string | number,        -- "50%" or absolute number
  position = "left" | "right" | "top" | "bottom" | nil,
}

-- For tabs
TabConfig = {
  name = string | nil,
}

-- For floats
FloatConfig = {
  width = string | number,        -- "80%" or absolute
  height = string | number,       -- "80%" or absolute
  position = "center" | "top-left" | "top-center" | ...,
  row = number | string | nil,   -- Override calculated row
  col = number | string | nil,    -- Override calculated col
  relative = "editor" | "win" | "cursor",
  anchor = "NW" | "NE" | "SW" | "SE",
  border = "single" | "double" | "rounded" | "none" | table,
  style = "minimal" | "default",
  zindex = number | nil,
  focusable = boolean,
}

-- For containers
ContainerConfig = {
  -- Container-specific options
}
```

### BufferSpec

```lua
BufferSpec = {
  type = "terminal" | "buffer" | "file" | "function" | "scratch",
  source = string | number | function,
  options = {
    -- Terminal options
    cmd = string | nil,
    env = table | nil,
    cwd = string | nil,
    clear_env = boolean,
    
    -- Buffer options
    buftype = string | nil,
    filetype = string | nil,
    readonly = boolean,
    modifiable = boolean,
    
    -- Session options
    tmux = boolean | string,      -- true or session name
    abduco = boolean | string,
    
    -- Lifecycle
    persistent = boolean,         -- Keep buffer when hidden
    recreate_on_show = boolean,   -- Recreate buffer each show
  },
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
  on_focus = function(experience: Experience, window_id: number): nil,
  on_buffer_enter = function(experience: Experience, buffer_id: number): nil,
  on_window_close = function(experience: Experience, window_id: number): nil,
}
```

### StateManager

```lua
StateManager = {
  experiences = {},               -- Map<id, Experience>
  active_experiences = {},        -- Set<id>
  window_to_experience = {},      -- Map<window_id, experience_id>
  buffer_to_experience = {},      -- Map<buffer_id, experience_id>
  groups = {},                    -- Map<group_name, Group>
  
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
  assert(opts.layout, "Layout required")
  
  -- 2. Check if already exists
  if state_manager.experiences[opts.id] then
    error("Experience already exists: " .. opts.id)
  end
  
  -- 3. Create experience object
  local experience = {
    id = opts.id,
    state = "created",
    layout = normalize_layout(opts.layout),
    metadata = opts.metadata or {},
    hooks = opts.hooks or {},
    windows = {},
    buffers = {},
    window_configs = {},
    buffer_specs = {},
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
  
  -- 7. Extract buffer specs from layout
  extract_buffer_specs(experience)
  
  -- 8. Execute after_create hook
  if experience.hooks.after_create then
    experience.hooks.after_create(experience)
  end
  
  -- 9. Emit event
  state_manager.on_experience_created(experience)
  
  return experience
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
    return
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
  
  -- 3. Create or restore buffers
  create_buffers(experience)
  
  -- 4. Create windows according to layout
  create_windows(experience)
  
  -- 5. Set up window options
  configure_windows(experience)
  
  -- 6. Register window mappings
  register_window_mappings(experience)
  
  -- 7. Update state
  experience.state = "visible"
  experience.last_shown_at = vim.loop.now()
  table.insert(state_manager.active_experiences, id)
  
  -- 8. Update window/buffer mappings
  for _, win_id in ipairs(experience.windows) do
    state_manager.window_to_experience[win_id] = id
  end
  for _, buf_id in ipairs(experience.buffers) do
    state_manager.buffer_to_experience[buf_id] = id
  end
  
  -- 9. Focus main window
  focus_experience(experience)
  
  -- 10. Execute after_show hook
  if experience.hooks.after_show then
    experience.hooks.after_show(experience)
  end
  
  -- 11. Emit event
  state_manager.on_experience_shown(experience)
end
```

### Window Creation (Recursive)

```lua
function create_windows(experience, layout, parent_win_id)
  parent_win_id = parent_win_id or 0  -- 0 = editor
  
  if layout.type == "float" then
    -- Create floating window
    local win_config = calculate_float_config(layout.config)
    local buf_id = get_or_create_buffer(experience, layout.buffer)
    local win_id = vim.api.nvim_open_win(buf_id, true, win_config)
    
    layout.window_id = win_id
    layout.buffer_id = buf_id
    table.insert(experience.windows, win_id)
    
    -- Save config for restoration
    experience.window_configs[win_id] = vim.api.nvim_win_get_config(win_id)
    
    return win_id
    
  elseif layout.type == "split" then
    -- Create split
    local current_win = vim.api.nvim_get_current_win()
    
    -- Save current window config
    local saved_config = save_window_state(current_win)
    
    -- Create split
    if layout.config.direction == "horizontal" then
      vim.cmd("split")
    else
      vim.cmd("vsplit")
    end
    
    local split_win = vim.api.nvim_get_current_win()
    
    -- Resize if needed
    if layout.config.size then
      resize_split(split_win, layout.config)
    end
    
    -- Set buffer
    if layout.buffer then
      local buf_id = get_or_create_buffer(experience, layout.buffer)
      vim.api.nvim_win_set_buf(split_win, buf_id)
      layout.buffer_id = buf_id
    end
    
    layout.window_id = split_win
    table.insert(experience.windows, split_win)
    experience.window_configs[split_win] = save_window_state(split_win)
    
    -- Process children
    if layout.children then
      for _, child_layout in ipairs(layout.children) do
        child_layout.parent_layout = layout
        create_windows(experience, child_layout, split_win)
      end
    end
    
    -- Restore focus
    vim.api.nvim_set_current_win(current_win)
    
    return split_win
    
  elseif layout.type == "tab" then
    -- Create new tab
    vim.cmd("tabnew")
    local tab_nr = vim.api.nvim_get_current_tabpage()
    
    -- Process children (typically splits/floats)
    if layout.children then
      for _, child_layout in ipairs(layout.children) do
        child_layout.parent_layout = layout
        create_windows(experience, child_layout, 0)
      end
    end
    
    return tab_nr
    
  elseif layout.type == "container" then
    -- Container just groups children
    if layout.children then
      for _, child_layout in ipairs(layout.children) do
        child_layout.parent_layout = layout
        create_windows(experience, child_layout, parent_win_id)
      end
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
    return
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
  for _, win_id in ipairs(experience.windows) do
    if vim.api.nvim_win_is_valid(win_id) then
      experience.window_configs[win_id] = vim.api.nvim_win_get_config(win_id)
    end
  end
  
  -- 4. Close windows
  for _, win_id in ipairs(experience.windows) do
    if vim.api.nvim_win_is_valid(win_id) then
      vim.api.nvim_win_close(win_id, true)
    end
  end
  
  -- 5. Clean up buffers (if not persistent)
  for _, buf_id in ipairs(experience.buffers) do
    local spec = experience.buffer_specs[buf_id]
    if spec and not spec.options.persistent then
      if vim.api.nvim_buf_is_valid(buf_id) then
        vim.api.nvim_buf_delete(buf_id, { force = true })
      end
    end
  end
  
  -- 6. Clear window/buffer mappings
  for _, win_id in ipairs(experience.windows) do
    state_manager.window_to_experience[win_id] = nil
  end
  for _, buf_id in ipairs(experience.buffers) do
    state_manager.buffer_to_experience[buf_id] = nil
  end
  
  -- 7. Update state
  experience.state = "hidden"
  experience.last_hidden_at = vim.loop.now()
  experience.windows = {}
  
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
end
```

### Buffer Management

```lua
function get_or_create_buffer(experience, buffer_spec)
  -- Check if buffer already exists and is valid
  if buffer_spec.buffer_id and vim.api.nvim_buf_is_valid(buffer_spec.buffer_id) then
    -- Check if we should recreate
    if buffer_spec.options.recreate_on_show then
      vim.api.nvim_buf_delete(buffer_spec.buffer_id, { force = true })
    else
      return buffer_spec.buffer_id
    end
  end
  
  local buf_id
  
  if buffer_spec.type == "terminal" then
    -- Create terminal buffer
    buf_id = vim.api.nvim_create_buf(true, true)
    vim.bo[buf_id].bufhidden = "hide"
    vim.bo[buf_id].filetype = "tfling"
    
    -- Start terminal job
    local cmd = buffer_spec.source
    if buffer_spec.options.tmux or buffer_spec.options.abduco then
      cmd = create_session_cmd(buffer_spec)
    end
    
    local job_id = vim.fn.termopen(cmd, {
      on_exit = function()
        -- Handle terminal exit
        handle_terminal_exit(experience, buf_id)
      end,
    })
    
    buffer_spec.job_id = job_id
    
  elseif buffer_spec.type == "buffer" then
    -- Use existing buffer
    if type(buffer_spec.source) == "number" then
      buf_id = buffer_spec.source
    else
      error("Invalid buffer source")
    end
    
  elseif buffer_spec.type == "file" then
    -- Open file buffer
    buf_id = vim.fn.bufadd(buffer_spec.source)
    vim.fn.bufload(buf_id)
    
  elseif buffer_spec.type == "function" then
    -- Create buffer and call function
    buf_id = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_call(buf_id, function()
      buffer_spec.source(experience, buf_id)
    end)
    
  elseif buffer_spec.type == "scratch" then
    -- Create scratch buffer
    buf_id = vim.api.nvim_create_buf(true, true)
    vim.bo[buf_id].buftype = "nofile"
    vim.bo[buf_id].bufhidden = "hide"
  end
  
  -- Apply buffer options
  if buffer_spec.options then
    apply_buffer_options(buf_id, buffer_spec.options)
  end
  
  -- Store buffer spec
  experience.buffer_specs[buf_id] = buffer_spec
  
  -- Track buffer
  table.insert(experience.buffers, buf_id)
  
  return buf_id
end
```

### Dependency Graph

```lua
function build_dependency_graph(experience)
  -- Add this experience as dependent of its dependencies
  for _, dep_id in ipairs(experience.depends_on) do
    local dep = state_manager.experiences[dep_id]
    if dep then
      if not vim.tbl_contains(dep.dependents, experience.id) then
        table.insert(dep.dependents, experience.id)
      end
    end
  end
  
  -- Check for circular dependencies
  if has_circular_dependency(experience) then
    error("Circular dependency detected involving: " .. experience.id)
  end
end

function has_circular_dependency(experience, visited, path)
  visited = visited or {}
  path = path or {}
  
  if visited[experience.id] then
    return false  -- Already checked
  end
  
  if vim.tbl_contains(path, experience.id) then
    return true  -- Circular!
  end
  
  table.insert(path, experience.id)
  
  for _, dep_id in ipairs(experience.depends_on) do
    local dep = state_manager.experiences[dep_id]
    if dep and has_circular_dependency(dep, visited, path) then
      return true
    end
  end
  
  table.remove(path)
  visited[experience.id] = true
  
  return false
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
          for i, w_id in ipairs(experience.windows) do
            if w_id == win_id then
              table.remove(experience.windows, i)
              break
            end
          end
          
          -- If no windows left, hide experience
          if #experience.windows == 0 then
            hide_experience(exp_id)
          end
          
          -- Execute hook
          if experience.hooks.on_window_close then
            experience.hooks.on_window_close(experience, win_id)
          end
        end
        
        state_manager.window_to_experience[win_id] = nil
      end
    end,
  })
  
  -- Window focus
  vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      local win_id = vim.api.nvim_get_current_win()
      local exp_id = state_manager.window_to_experience[win_id]
      
      if exp_id then
        local experience = state_manager.experiences[exp_id]
        if experience and experience.hooks.on_focus then
          experience.hooks.on_focus(experience, win_id)
        end
      end
    end,
  })
  
  -- Buffer enter
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
      local buf_id = vim.api.nvim_get_current_buf()
      local exp_id = state_manager.buffer_to_experience[buf_id]
      
      if exp_id then
        local experience = state_manager.experiences[exp_id]
        if experience and experience.hooks.on_buffer_enter then
          experience.hooks.on_buffer_enter(experience, buf_id)
        end
      end
    end,
  })
end
```

## Performance Considerations

### Window Creation Optimization

- Batch window operations where possible
- Minimize redraws during layout creation
- Use `nvim_win_call` to avoid focus changes

### State Lookup Optimization

- Use hash tables for O(1) lookups
- Cache frequently accessed data
- Lazy-load buffer contents when possible

### Memory Management

- Clean up invalid window/buffer references
- Limit saved window configs for hidden experiences
- Allow buffer deletion when not persistent

## Error Handling

### Validation

- Validate layout structure before creation
- Check for circular dependencies
- Verify buffer sources exist
- Validate window configurations

### Recovery

- Handle invalid window/buffer IDs gracefully
- Recover from failed hook execution
- Restore state on errors
- Log errors for debugging

## Testing Strategy

### Unit Tests

- StateManager operations
- Layout parsing and validation
- Buffer creation
- Dependency graph building

### Integration Tests

- Experience lifecycle
- Window creation and restoration
- Hook execution
- Group operations

### E2E Tests

- Complex layout scenarios
- Multi-experience interactions
- Error recovery
- Performance benchmarks
