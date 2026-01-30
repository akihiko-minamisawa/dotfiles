return {
  "Maduki-tech/nvim-plantuml",
  init = function()
    -- .puml ファイルを plantuml として認識（プラグイン読み込み前に実行）
    vim.filetype.add({
      extension = {
        puml = "plantuml",
        plantuml = "plantuml",
      },
    })
  end,
  ft = "plantuml",
  config = function()
    require("plantuml").setup({
      output_dir = "/tmp",
      viewer = "open",
      auto_refresh = true,
    })
  end,
  keys = {
    { "<leader>pp", "<cmd>PlantUML preview<cr>", desc = "PlantUML Preview", ft = "plantuml" },
    { "<leader>pe", "<cmd>PlantUML export png<cr>", desc = "PlantUML Export PNG", ft = "plantuml" },
  },
}
