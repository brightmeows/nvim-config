-- grug-far：多文件搜索替换。行为源：LazyVim plugins/editor.lua 的 grug-far
-- spec（cmd + keys；键位走 spec keys，触发前即注册）。
return {
  "https://github.com/MagicDuck/grug-far.nvim",
  cmd = { "GrugFar", "GrugFarWithin" },
  -- stylua: ignore
  keys = {
    {
      "<leader>sr",
      function()
        local grug = require("grug-far")
        local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
        grug.open({
          transient = true,
          prefills = {
            filesFilter = ext and ext ~= "" and "*." .. ext or nil,
          },
        })
      end,
      mode = { "n", "x" },
      desc = "Search and Replace",
    },
  },
  config = function()
    require("grug-far").setup({ headerMaxWidth = 80 })
  end,
}
