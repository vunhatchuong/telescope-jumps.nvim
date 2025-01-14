# :telescope: telescope-jumps.nvim
Jumps in change and jump lists in the current file.
The change list is sorted and doesn't have duplicates.

# Installation

### lazy.nvim
```lua
{'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    dependencies = {
        { 'amiroslaw/telescope-jumps.nvim' },
    },
    opts = {
        extensions = {
            jumps = {
                max_results = 5, -- default is nil
                line_distance = 5 -- default is nil
            },
        },
    },
},
```

### Vim-Plug

```viml
Plug "nvim-telescope/telescope.nvim"
Plug "amiroslaw/telescope-jumps.nvim"
```

# Setup and Configuration

```lua
require('telescope').load_extension('jumps')
```

# Usage
`:Telescope jumps changes`
`:Telescope jumps jumpbuff`

Plugin is inspired by the extension [LinArcX](https://github.com/LinArcX/telescope-jumps.nvim), and buildin finder `jumps`
