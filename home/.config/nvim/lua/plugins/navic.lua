return {
  "SmiteshP/nvim-navic",
  dependencies = { "neovim/nvim-lspconfig" },
  opts = {
    auto_attach = true,
    highlight = true,
    lsp = { auto_attach = true },
  },
  init = function()
    vim.o.winbar = "%t > %{%v:lua.require('nvim-navic').get_location()%}"
  end,
}
