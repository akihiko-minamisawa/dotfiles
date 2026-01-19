-- Neo-tree file explorer configuration
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      close_if_last_window = true,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      filesystem = {
        follow_current_file = {
          enabled = true,
        },
        use_libuv_file_watcher = true,
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_by_name = {
            -- ".git",
            -- ".DS_Store",
          },
          never_show = {},
        },
      },
      window = {
        position = "left",
        width = 30,
        auto_expand_width = true,
        mappings = {
          ["<space>"] = "none",
        },
      },
    })

    -- Keymapping: Toggle Neo-tree with <leader>e
    vim.keymap.set("n", "<leader>t", ":Neotree toggle<CR>", {
      desc = "Toggle Neo-tree",
      silent = true
    })
  end,
}
