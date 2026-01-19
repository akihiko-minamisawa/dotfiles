return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "jdtls",  -- Java
          "ts_ls",  -- TypeScript/JavaScript
          "gopls",  -- Go
          "lua_ls", -- Lua
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      local on_attach = require("config.lsp_on_attach")

      vim.lsp.config.ts_ls = {
        on_attach = on_attach,
        filetypes = {
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
        },
      }
      vim.lsp.enable("ts_ls")

      vim.lsp.config.gopls = {
        on_attach = on_attach,
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
      }
      vim.lsp.enable("gopls")

      vim.lsp.config.lua_ls = {
        on_attach = on_attach,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
          },
        },
      }
      vim.lsp.enable("lua_ls")
    end,
  },
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
  },
}
