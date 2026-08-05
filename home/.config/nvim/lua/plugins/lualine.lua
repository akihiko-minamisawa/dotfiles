return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    -- Highlighted badge so unsaved changes are impossible to miss
    local modified = {
      function()
        return vim.bo.modified and "[+]" or ""
      end,
      color = { fg = "#1a1a1a", bg = "#e5c07b", gui = "bold" },
      padding = { left = 1, right = 1 },
    }

    require("lualine").setup({
      options = {
        theme = "auto",
        globalstatus = true, -- single statusline across splits (sets laststatus=3)
        section_separators = "",
        component_separators = "|",
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = {
          -- suppress the built-in [+] so it isn't shown twice (the badge below handles it)
          { "filename", path = 1, symbols = { modified = "", readonly = "[RO]", unnamed = "[No Name]", newfile = "[New]" } },
          modified,
        },
        lualine_x = { "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    })
  end,
}
