return {
  "folke/lazydev.nvim",
  ft = "lua",
  opts = {
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      "lazy.nvim",
      "mason.nvim",
      "mason-lspconfig.nvim",
      "nvim-jdtls",
      "gitsigns.nvim",
      "nvim-highlight-colors",
      "neo-tree.nvim",
    },
  },
}
