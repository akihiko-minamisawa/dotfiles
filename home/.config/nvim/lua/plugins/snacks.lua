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
  config = function(_, opts)
    require("snacks").setup(opts)

    -- Workaround for a snacks.nvim bug: when an image buffer leaves every
    -- window even briefly, its placement goes hidden, but for images opened
    -- directly as files (non-inline) nothing ever calls show() again, so
    -- that image never renders afterwards. If a placement is still hidden
    -- while some window is showing the buffer, un-hide it.
    local Placement = require("snacks.image.placement")
    local update = Placement.update
    Placement.update = function(self, ...)
      if self.hidden and not (self.opts and self.opts.inline) and #self:wins() > 0 then
        self.hidden = false
      end
      return update(self, ...)
    end

    -- Workaround for the delete-side of the same snacks bug: for direct
    -- (non-placeholder) display, hiding a placement never sends a kitty
    -- delete to the terminal, so the previous image stays on screen when
    -- switching buffers. Send the delete explicitly on the hide transition.
    -- (Restoring is handled by the update wrapper above, which unhides and
    -- re-places when the buffer becomes visible again.)
    local Terminal = require("snacks.image.terminal")
    local hide = Placement.hide
    Placement.hide = function(self)
      local was_hidden = self.hidden
      hide(self)
      if not was_hidden and self.hidden
          and not (self.opts and self.opts.inline)
          and not Terminal.env().placeholders then
        Terminal.request({ a = "d", d = "i", i = self.img.id, p = self.id })
      end
    end
  end,
  keys = {
    { "<leader>ff", function() Snacks.picker.files() end,   desc = "Find files" },
    { "<leader>fg", function() Snacks.picker.grep() end,    desc = "Live grep" },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fh", function() Snacks.picker.help() end,    desc = "Help tags" },
    { "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>fr", function() Snacks.picker.recent() end,  desc = "Recent files" },
    { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git blame line" },
    { "<leader>gB", function() Snacks.gitbrowse() end,      desc = "Git browse" },
    { "<leader>gl", function() Snacks.lazygit() end,        desc = "Lazygit" },
    { "<leader>t",  function() Snacks.explorer() end,       desc = "Toggle Explorer" },
  },
}
