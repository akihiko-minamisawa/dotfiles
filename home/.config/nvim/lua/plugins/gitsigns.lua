return {
  "lewis6991/gitsigns.nvim",
  config = function()
    require("gitsigns").setup({
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 500,
      },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("<leader>gp", gs.preview_hunk_inline, "Preview hunk inline")
        map("<leader>gP", gs.preview_hunk, "Preview hunk (float)")
        map("<leader>gd", gs.diffthis, "Diff this file")
        map("<leader>gs", gs.stage_hunk, "Stage hunk")
        map("<leader>gr", gs.reset_hunk, "Reset hunk")
      end,
    })
  end,
}

