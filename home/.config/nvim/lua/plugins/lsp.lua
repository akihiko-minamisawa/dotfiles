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
          "eslint", -- ESLint
          "gopls",  -- Go
          "lua_ls", -- Lua
          "yamlls", -- YAML (incl. OpenAPI specs)
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

      vim.lsp.config.eslint = {
        on_attach = on_attach,
        filetypes = {
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
        },
      }
      vim.lsp.enable("eslint")

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
            diagnostics = { globals = { "vim", "Snacks" } },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
          },
        },
      }
      vim.lsp.enable("lua_ls")

      -- YAML. Main use is reading big OpenAPI specs (SPF の IF 設計 yaml):
      -- `gO` gives a paths → operations outline, <leader>fs a fuzzy version of
      -- it, and the server also exposes each `$ref` as a documentLink (which
      -- nvim has no default mapping for -- see lsplinks.nvim if that is wanted).
      vim.lsp.config.yamlls = {
        on_attach = on_attach,
        settings = {
          yaml = {
            -- Alphabetical-key diagnostics are noise in hand-authored specs.
            keyOrdering = false,
            -- Completion/validation/hover need a schema. SchemaStore matches on
            -- filename, which the SPF_*_API_Definition_v*.yaml files do not, so
            -- associate the OpenAPI 3.0 schema explicitly (spec.openapis.org is
            -- the canonical host; the OAI repo's raw.githubusercontent path 404s).
            -- Fetched over the network; without it the outline and $ref links
            -- still work, only completion/validation go away.
            schemas = {
              ["https://spec.openapis.org/oas/3.0/schema/2021-09-28"] = {
                "*API_Definition*.yaml",
                "*openapi*.yaml",
                "*openapi*.yml",
              },
            },
          },
        },
      }
      vim.lsp.enable("yamlls")
    end,
  },
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
  },
}
