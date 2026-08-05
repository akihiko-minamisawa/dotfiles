-- Main Neovim configuration file

-- Load basic options
require("config.options")

-- Log keystrokes for /vim-coach analysis (see lua/config/keylog.lua)
require("config.keylog").setup()

-- Load lazy.nvim (plugin manager)
require("config.lazy")
