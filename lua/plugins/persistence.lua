-- persistence：会话管理。行为源：LazyVim plugins/util.lua 的 persistence spec
-- （event=BufReadPre + keys 字段——键位在启动期注册，无文件打开时也可用，
-- 与基线同构）。
return {
  "https://github.com/folke/persistence.nvim",
  event = "BufReadPre",
  -- stylua: ignore
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>qS", function() require("persistence").select() end, desc = "Select Session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
  },
  config = function()
    require("persistence").setup({})
  end,
}
