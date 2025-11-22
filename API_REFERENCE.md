# Tfling v2 API Reference

## Core API

### `tfling.create(opts) -> Experience`

Create a new experience.

**Parameters:**
- `opts.id` (string, required): Unique identifier
- `opts.layout` (Layout, required): Layout definition
- `opts.hooks` (Hooks, optional): Lifecycle hooks
- `opts.metadata` (table, optional): Custom metadata
- `opts.depends_on` (string[], optional): Experience dependencies

**Returns:** Experience object

**Example:**
```lua
local exp = tfling.create({
  id = "my-tool",
  layout = { type = "float", ... },
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

### `experience:layout(new_layout) -> nil`

Update the layout definition (does not apply immediately).

**Parameters:**
- `new_layout` (Layout): New layout definition

---

### `experience:apply_layout() -> boolean, error`

Reapply the current layout (recreates windows).

**Returns:** `true` on success, `false, error` on failure

---

### `experience:resize_window(win_id, opts) -> boolean, error`

Resize a specific window in this experience.

**Parameters:**
- `win_id` (number): Window ID
- `opts` (table): `{ width = "50%" | number, height = "50%" | number }`

**Returns:** `true` on success, `false, error` on failure

---

### `experience:reposition_window(win_id, opts) -> boolean, error`

Reposition a floating window.

**Parameters:**
- `win_id` (number): Window ID
- `opts` (table): `{ position = "center" | ..., row = number, col = number }`

**Returns:** `true` on success, `false, error` on failure

---

### `experience:focus_window(win_id) -> nil`

Focus a specific window in this experience.

**Parameters:**
- `win_id` (number): Window ID

---

## Layout Types

### Float Layout

```lua
{
  type = "float",
  config = {
    width = "80%" | number,
    height = "60%" | number,
    position = "center" | "top-left" | "top-center" | "top-right" |
               "bottom-left" | "bottom-center" | "bottom-right" |
               "left-center" | "right-center",
    row = number | nil,        -- Override calculated row
    col = number | nil,        -- Override calculated col
    relative = "editor" | "win" | "cursor",
    anchor = "NW" | "NE" | "SW" | "SE",
    border = "single" | "double" | "rounded" | "none" | table,
    style = "minimal" | "default",
    zindex = number | nil,
    focusable = true | false,
  },
  buffer = BufferSpec,
}
```

### Split Layout

```lua
{
  type = "split",
  config = {
    direction = "horizontal" | "vertical",
    size = "50%" | number,
    position = "left" | "right" | "top" | "bottom" | nil,
  },
  buffer = BufferSpec | nil,
  children = Layout[] | nil,
}
```

### Tab Layout

```lua
{
  type = "tab",
  config = {
    name = string | nil,
  },
  children = Layout[],
}
```

### Container Layout

```lua
{
  type = "container",
  children = Layout[],
}
```

## Buffer Specifications

### Terminal Buffer

```lua
{
  type = "terminal",
  source = "bash" | "htop" | string,
  options = {
    env = table | nil,
    cwd = string | nil,
    clear_env = boolean,
    tmux = true | string | false,
    abduco = true | string | false,
    persistent = boolean,
    recreate_on_show = boolean,
  },
}
```

### File Buffer

```lua
{
  type = "file",
  source = "/path/to/file",
  options = {
    readonly = boolean,
    modifiable = boolean,
    filetype = string | nil,
  },
}
```

### Function Buffer

```lua
{
  type = "function",
  source = function(experience, buffer_id)
    -- Setup buffer content
  end,
  options = {
    filetype = string | nil,
    buftype = string | nil,
  },
}
```

### Scratch Buffer

```lua
{
  type = "scratch",
  options = {
    filetype = string | nil,
    buftype = "nofile" | "nowrite" | nil,
  },
}
```

### Existing Buffer

```lua
{
  type = "buffer",
  source = buffer_number,
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
  on_focus = function(experience, window_id) -> nil,
  on_buffer_enter = function(experience, buffer_id) -> nil,
  on_window_close = function(experience, window_id) -> nil,
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

## Layout Builder

### `tfling.layout() -> Builder`

Create a layout builder.

### `builder:split(direction, config) -> Builder`

Add a split to the layout.

**Parameters:**
- `direction` (string): `"horizontal"` or `"vertical"`
- `config` (table): Split configuration

**Returns:** Builder (for chaining)

### `builder:tab(config) -> Builder`

Add a tab to the layout.

**Parameters:**
- `config` (table): Tab configuration

**Returns:** Builder (for chaining)

### `builder:float(config) -> Builder`

Add a float to the layout.

**Parameters:**
- `config` (table): Float configuration

**Returns:** Builder (for chaining)

### `builder:buffer(spec) -> Builder`

Set the buffer for the current layout node.

**Parameters:**
- `spec` (BufferSpec): Buffer specification

**Returns:** Builder (for chaining)

### `builder:end_split() -> Builder`

End the current split context.

**Returns:** Builder (for chaining)

### `builder:build() -> Layout`

Build and return the layout.

**Returns:** Layout object

**Example:**
```lua
local layout = tfling.layout()
  :split("horizontal", { size = "100%" })
    :split("vertical", { size = "30%" })
      :buffer({ type = "file", source = "left.txt" })
    :end_split()
    :split("vertical", { size = "70%" })
      :buffer({ type = "file", source = "right.txt" })
    :end_split()
  :end_split()
  :build()
```

## Experience Object Properties

```lua
experience = {
  id = string,                    -- Unique identifier
  state = string,                  -- Current state
  layout = Layout,                 -- Layout definition
  metadata = table,                -- Custom metadata
  hooks = Hooks,                   -- Lifecycle hooks
  windows = number[],              -- Window IDs
  buffers = number[],              -- Buffer IDs
  depends_on = string[],           -- Dependencies
  dependents = string[],           -- Dependents (computed)
  created_at = number,             -- Timestamp
  last_shown_at = number,          -- Timestamp
  last_hidden_at = number,         -- Timestamp
}
```

## Common Patterns

### Simple Toggle

```lua
local exp = tfling.create({ id = "tool", layout = {...} })
vim.keymap.set("n", "<leader>t", function() exp:toggle() end)
```

### Conditional Show

```lua
if tfling.state("tool") ~= "visible" then
  tfling.show("tool")
end
```

### Hook with State

```lua
local exp = tfling.create({
  id = "tool",
  layout = {...},
  hooks = {
    after_show = function(exp)
      exp.metadata.shown_count = (exp.metadata.shown_count or 0) + 1
    end,
  },
})
```

### Dynamic Layout

```lua
local exp = tfling.create({ id = "tool", layout = initial_layout })

-- Later, update layout
exp:layout(new_layout)
exp:apply_layout()
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
local success, err = tfling.show("my-tool")
if not success then
  vim.notify("Failed to show: " .. err, vim.log.levels.ERROR)
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

### Directions

```lua
"horizontal" | "vertical"
```

### States

```lua
"created" | "visible" | "hidden" | "destroyed"
```

### Border Styles

```lua
"single" | "double" | "rounded" | "none" | table
```

---

**Note:** This is a reference document. See DESIGN.md for detailed explanations and EXAMPLES.md for usage examples.
