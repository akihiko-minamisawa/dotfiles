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
    -- Highlight all LSP references of the symbol under the cursor
    words = { enabled = true, debounce = 100 },
    quickfile = { enabled = true },
    -- Inside tmux this uses kitty unicode placeholders (SNACKS_* overrides in
    -- tmux.conf); requires a placeholder-capable terminal such as WezTerm-dev.
    image = { enabled = true },
  },
  keys = {
    { "<leader>ff", function() Snacks.picker.files() end,   desc = "Find files" },
    { "<leader>fg", function() Snacks.picker.grep() end,    desc = "Live grep" },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fh", function() Snacks.picker.help() end,    desc = "Help tags" },
    { "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>fr", function() Snacks.picker.recent() end,  desc = "Recent files" },
    -- LSP outline as a picker; on an OpenAPI yaml this is the paths → operations tree
    { "<leader>fs", function() Snacks.picker.lsp_symbols() end, desc = "Document symbols" },
    { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git blame line" },
    { "<leader>gB", function() Snacks.gitbrowse() end,      desc = "Git browse" },
    { "<leader>gl", function() Snacks.lazygit() end,        desc = "Lazygit" },
    { "<leader>t",  function() Snacks.explorer() end,       desc = "Toggle Explorer" },
    { "]]",         function() Snacks.words.jump(vim.v.count1, true) end,  desc = "Next reference",     mode = { "n", "t" } },
    { "[[",         function() Snacks.words.jump(-vim.v.count1, true) end, desc = "Previous reference", mode = { "n", "t" } },
  },
}
