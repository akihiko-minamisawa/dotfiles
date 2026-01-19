-- Java LSP Configuration using nvim-jdtls
local jdtls = require("jdtls")

-- Lombok support
local lombok_path = vim.fn.expand("~/.local/share/nvim/mason/packages/jdtls/lombok.jar")

-- Load shared on_attach function
local on_attach = require("config.lsp_on_attach")

local config = {
  cmd = {
    "jdtls",
    "--jvm-arg=-javaagent:" .. lombok_path,
  },
  root_dir = vim.fs.dirname(vim.fs.find({ ".gradlew", ".git", "mvnw", "pom.xml" }, { upward = true })[1]),
  on_attach = on_attach,
}

jdtls.start_or_attach(config)
