return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    dashboard = { enabled = true, autoshow = true },
    explorer = {
      enabled = true,
      hidden = true,
      ignored = true,
    },
    picker = {
      enabled = true,
      sources = {
        files = {
          hidden = true,
          ignored = true,
        },
        grep = {
          hidden = true,
          ignored = true,
        },
        explorer = {
          hidden = true,
          ignored = true,
          layout = {
            layout = {
              width = 50,
            },
          },
        },
      },
    },
    notifier = { enabled = true },
    indent = { enabled = true },
    quickfile = { enabled = true },
    image = { enabled = true },
  },
  keys = {
    { "<leader>ff", function() Snacks.picker.files() end,   desc = "Find files" },
    { "<leader>fg", function() Snacks.picker.grep() end,    desc = "Live grep" },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fh", function() Snacks.picker.help() end,    desc = "Help tags" },
    { "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>fr", function() Snacks.picker.recent() end,  desc = "Recent files" },
    { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git blame line" },
    { "<leader>gB", function() Snacks.gitbrowse() end,      desc = "Git browse" },
    { "<leader>t",  function() Snacks.explorer() end,       desc = "Toggle Explorer" },
  },
}
