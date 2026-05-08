return {
  "zk-org/zk-nvim",
  ft = "markdown",
  cmd = { "ZkNew", "ZkNotes", "ZkTags", "ZkBacklinks", "ZkLinks", "ZkIndex", "ZkMatch" },
  config = function()
    require("zk").setup({
      picker = "snacks_picker",
      lsp = {
        config = {
          cmd = { "zk", "lsp" },
          name = "zk",
        },
        auto_attach = {
          enabled = true,
          filetypes = { "markdown" },
        },
      },
    })

    local map = vim.keymap.set
    map("n", "<leader>zn", function()
      vim.ui.input({ prompt = "Title: " }, function(title)
        if title and title ~= "" then
          require("zk.commands").get("ZkNew")({ title = title })
        end
      end)
    end, { desc = "zk: new note" })
    map("n", "<leader>zo", "<cmd>ZkNotes { sort = { 'modified' } }<cr>", { desc = "zk: open note" })
    map("n", "<leader>zt", "<cmd>ZkTags<cr>",      { desc = "zk: tags" })
    map("n", "<leader>zb", "<cmd>ZkBacklinks<cr>", { desc = "zk: backlinks" })
    map("n", "<leader>zl", "<cmd>ZkLinks<cr>",     { desc = "zk: links" })
    map("v", "<leader>zf", ":'<,'>ZkMatch<cr>",    { desc = "zk: search selection" })
  end,
}
