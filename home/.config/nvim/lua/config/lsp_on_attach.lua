-- Shared on_attach function for all LSP servers
-- This file defines common keybindings used across all language servers

local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr, noremap = true, silent = true }

  -- Navigation
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

  -- Documentation
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

  -- Refactoring
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

  -- Formatting
  vim.keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format({ async = true })
  end, opts)

  -- (Diagnostics keymaps are defined globally in config/options.lua so they
  --  also work for LSP clients that don't go through this on_attach, e.g. zk.)
end

return on_attach

