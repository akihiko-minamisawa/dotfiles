return {
  "stevearc/oil.nvim",
  dependencies = { { "nvim-tree/nvim-web-devicons", version = "*" } },
  -- No lazy-loading so oil is the default handler when opening a directory
  lazy = false,
  opts = {
    default_file_explorer = true,
    view_options = {
      show_hidden = true,
    },
    keymaps = {
      ["q"] = "actions.close",
      ["Y"] = { "actions.yank_entry", desc = "Yank filepath" },
    },
  },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
    { "<leader>o", "<cmd>Oil<cr>", desc = "Open Oil" },
  },
}
