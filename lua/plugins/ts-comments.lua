-- ts-comments：注释增强。行为源：LazyVim plugins/coding.lua 的 ts-comments spec。
return {
  src = "https://github.com/folke/ts-comments.nvim",
  name = "ts-comments.nvim",
  config = function()
    require("ts-comments").setup({})
  end,
}
