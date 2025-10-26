# tfling.nvim

A terminal window plugin (++)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "BlakeASmith/tfling.nvim",
  config = function()
    require("tfling").setup({
      -- your configuration here
    })
  end
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "BlakeASmith/tfling.nvim",
  config = function()
    require("tfling").setup({
      -- your configuration here
    })
  end
}
```

## Configuration

```lua
require("tfling").setup({
})
```

## License

MIT
