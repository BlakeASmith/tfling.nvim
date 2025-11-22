# Tfling v2 API Reference

## Core API

### `tfling.create(opts) -> Experience`

Create a new experience.

**Parameters:**
- `opts.id` (string, required): Unique identifier
- `opts.hooks` (Hooks, optional): Lifecycle hooks
- `opts.metadata` (table, optional): Custom metadata
- `opts.depends_on` (string[], optional): Experience dependencies

**Returns:** Experience object

**Example:**
```lua
local exp = tfling.create({
  id = "my-tool",
  hooks = {
    after_show = function(exp) print("Shown!") end,
  },
})
```

---

### `tfling.show(id) -> boolean, error`

Show an experience.

**Parameters:**
- `id` (string): Experience ID

**Returns:** `true` on success, `false, error` on failure

---

### `tfling.hide(id) -> boolean, error`

Hide an experience.

**Parameters:**
- `id` (string): Experience ID

**Returns:** `true` on success, `false, error` on failure

---

### `tfling.toggle(id) -> boolean, error`

Toggle an experience (show if hidden, hide if visible).

**Parameters:**
- `id` (string): Experience ID

**Returns:** `true` on success, `false, error` on failure

---

### `tfling.destroy(id) -> boolean, error`

Destroy an experience (permanently remove).

**Parameters:**
- `id` (string): Experience ID

**Returns:** `true` on success, `false, error` on failure

---

### `tfling.get(id) -> Experience | nil`

Get an experience by ID.

**Parameters:**
- `id` (string): Experience ID

**Returns:** Experience object or `nil`

---

### `tfling.state(id) -> "visible" | "hidden" | "created" | "destroyed" | nil`

Get the current state of an experience.

**Parameters:**
- `id` (string): Experience ID

**Returns:** State string or `nil` if not found

---

### `tfling.list() -> Experience[]`

List all experiences.

**Returns:** Array of Experience objects

---

## Registration API

### `experience:register_window(win_id, options?) -> boolean, error`

Register a window with this experience.

**Parameters:**
- `win_id` (number): Window ID
- `options` (table, optional): Registration options

**Returns:** `true` on success, `false, error` on failure

**Example:**
```lua
local win = vim.api.nvim_open_win(buf, true, config)
exp:register_window(win, {
  close_on_hide = false,
  save_config = true,
})
```

---

### `experience:register_buffer(buf_id, options?) -> boolean, error`

Register a buffer with this experience.

**Parameters:**
- `buf_id` (number): Buffer ID
- `options` (table, optional): Registration options

**Returns:** `true` on success, `false, error` on failure

**Example:**
```lua
local buf = vim.api.nvim_create_buf(true, true)
exp:register_buffer(buf, {
  persistent = true,
})
```

---

### `experience:register_tab(tab_id, options?) -> boolean, error`

Register a tabpage with this experience.

**Parameters:**
- `tab_id` (number): Tabpage ID
- `options` (table, optional): Registration options

**Returns:** `true` on success, `false, error` on failure

**Example:**
```lua
local tab = vim.api.nvim_create_tabpage()
exp:register_tab(tab, {
  close_on_hide = false,
})
```

---

### `experience:register(elements) -> boolean, error`

Bulk register multiple elements.

**Parameters:**
- `elements` (table): `{ windows = {...}, buffers = {...}, tabs = {...} }`

**Returns:** `true` on success, `false, error` on failure

**Example:**
```lua
exp:register({
  windows = { win1, win2 },
  buffers = { buf1, buf2 },
  tabs = { tab1 },
})
```

---

### `experience:unregister_window(win_id) -> boolean, error`

Unregister a window from this experience.

**Parameters:**
- `win_id` (number): Window ID

**Returns:** `true` on success, `false, error` on failure

---

### `experience:unregister_buffer(buf_id) -> boolean, error`

Unregister a buffer from this experience.

**Parameters:**
- `buf_id` (number): Buffer ID

**Returns:** `true` on success, `false, error` on failure

---

### `experience:unregister_tab(tab_id) -> boolean, error`

Unregister a tabpage from this experience.

**Parameters:**
- `tab_id` (number): Tabpage ID

**Returns:** `true` on success, `false, error` on failure

---

## Experience Methods

### `experience:show() -> boolean, error`

Show this experience.

---

### `experience:hide() -> boolean, error`

Hide this experience.

---

### `experience:toggle() -> boolean, error`

Toggle this experience.

---

### `experience:destroy() -> boolean, error`

Destroy this experience.

---

### `experience:get_windows() -> number[]`

Get all registered window IDs.

**Returns:** Array of window IDs

---

### `experience:get_buffers() -> number[]`

Get all registered buffer IDs.

**Returns:** Array of buffer IDs

---

### `experience:get_tabs() -> number[]`

Get all registered tabpage IDs.

**Returns:** Array of tabpage IDs

---

### `experience:resize_window(win_id, opts) -> boolean, error`

Resize a registered window.

**Parameters:**
- `win_id` (number): Window ID
- `opts` (table): `{ width = number | string, height = number | string }`

**Returns:** `true` on success, `false, error` on failure

**Example:**
```lua
exp:resize_window(win_id, { width = 100, height = 50 })
exp:resize_window(win_id, { width = "+10%", height = "-5%" })
```

---

### `experience:reposition_window(win_id, opts) -> boolean, error`

Reposition a floating window.

**Parameters:**
- `win_id` (number): Window ID
- `opts` (table): `{ position = "center" | ..., row = number, col = number }`

**Returns:** `true` on success, `false, error` on failure

**Example:**
```lua
exp:reposition_window(win_id, { position = "bottom-right" })
exp:reposition_window(win_id, { row = 20, col = 30 })
```

---

### `experience:focus_window(win_id) -> nil`

Focus a specific window in this experience.

**Parameters:**
- `win_id` (number): Window ID

---

## Registration Options

### Window Options

```lua
{
  save_config = true,        -- Save window config for restoration (default: true)
  restore_on_show = true,    -- Restore window config when showing (default: true)
  close_on_hide = false,     -- Close window when hiding (default: false)
  close_on_destroy = true,   -- Close window when destroying (default: true)
}
```

### Buffer Options

```lua
{
  persistent = true,         -- Keep buffer when hiding (default: true)
  delete_on_destroy = false, -- Delete buffer when destroying (default: false)
}
```

### Tab Options

```lua
{
  close_on_hide = false,    -- Close tab when hiding (default: false)
  close_on_destroy = true,  -- Close tab when destroying (default: true)
}
```

## Hooks

### Lifecycle Hooks

```lua
hooks = {
  before_create = function(experience) -> nil | false,
  after_create = function(experience) -> nil,
  before_show = function(experience) -> nil | false,
  after_show = function(experience) -> nil,
  before_hide = function(experience) -> nil | false,
  after_hide = function(experience) -> nil,
  before_destroy = function(experience) -> nil | false,
  after_destroy = function(experience) -> nil,
}
```

### Event Hooks

```lua
hooks = {
  on_window_registered = function(experience, window_id) -> nil,
  on_buffer_registered = function(experience, buffer_id) -> nil,
  on_tab_registered = function(experience, tab_id) -> nil,
  on_window_closed = function(experience, window_id) -> nil,
  on_buffer_deleted = function(experience, buffer_id) -> nil,
  on_tab_closed = function(experience, tab_id) -> nil,
}
```

**Note:** Return `false` from `before_*` hooks to cancel the operation.

## Groups

### `tfling.group(name) -> Group`

Create or get an experience group.

**Parameters:**
- `name` (string): Group name

**Returns:** Group object

### `group:add(experience_id) -> nil`

Add an experience to the group.

**Parameters:**
- `experience_id` (string): Experience ID

### `group:remove(experience_id) -> nil`

Remove an experience from the group.

**Parameters:**
- `experience_id` (string): Experience ID

### `group:show() -> nil`

Show all experiences in the group.

### `group:hide() -> nil`

Hide all experiences in the group.

### `group:toggle() -> nil`

Toggle all experiences in the group.

## Experience Object Properties

```lua
experience = {
  id = string,                    -- Unique identifier
  state = string,                  -- Current state
  metadata = table,                -- Custom metadata
  hooks = Hooks,                   -- Lifecycle hooks
  windows = number[],              -- Window IDs
  buffers = number[],              -- Buffer IDs
  tabs = number[],                 -- Tabpage IDs
  depends_on = string[],           -- Dependencies
  dependents = string[],           -- Dependents (computed)
  created_at = number,             -- Timestamp
  last_shown_at = number,          -- Timestamp
  last_hidden_at = number,         -- Timestamp
}
```

## Common Patterns

### Simple Registration

```lua
local exp = tfling.create({ id = "tool" })

-- Create and register
local buf = vim.api.nvim_create_buf(true, true)
local win = vim.api.nvim_open_win(buf, true, config)
exp:register_window(win)
exp:register_buffer(buf)

-- Toggle
exp:toggle()
```

### Lazy Creation Pattern

```lua
local exp = tfling.create({
  id = "lazy-tool",
  hooks = {
    before_show = function(exp)
      if #exp.windows == 0 then
        -- Create windows
        local buf = create_buffer()
        local win = create_window(buf)
        exp:register_window(win)
        exp:register_buffer(buf)
      end
    end,
    before_hide = function(exp)
      -- Close windows
      for _, win_id in ipairs(exp.windows) do
        if vim.api.nvim_win_is_valid(win_id) then
          vim.api.nvim_win_close(win_id, true)
        end
      end
      exp.windows = {}
      exp.buffers = {}
    end,
  },
})
```

### Multi-Window Experience

```lua
local exp = tfling.create({ id = "multi-tool" })

-- Create multiple windows
local win1 = create_window1()
local win2 = create_window2()

-- Register all
exp:register_window(win1)
exp:register_window(win2)
```

### Group Management

```lua
local group = tfling.group("dev-tools")
group:add("file-tree")
group:add("terminal")
group:add("git-status")

vim.keymap.set("n", "<leader>dt", function() group:toggle() end)
```

## Error Handling

All methods that can fail return `boolean, error`:

```lua
local success, err = exp:register_window(win_id)
if not success then
  vim.notify("Failed to register: " .. err, vim.log.levels.ERROR)
end
```

## Constants

### Positions

```lua
"center"
"top-left" | "top-center" | "top-right"
"bottom-left" | "bottom-center" | "bottom-right"
"left-center" | "right-center"
```

### States

```lua
"created" | "visible" | "hidden" | "destroyed"
```

---

**Note:** This is a reference document. See DESIGN.md for detailed explanations and EXAMPLES.md for usage examples.
