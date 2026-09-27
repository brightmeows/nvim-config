-- lazydev：lua_ls 的 Neovim 库补全。行为源：LazyVim plugins/coding.lua 的
-- lazydev spec（ft + cmd 触发）。
-- 差异：library 条目中 LazyVim/lazy.nvim 自身路径已移除（发行版不存在了）。
return {
  "https://github.com/folke/lazydev.nvim",
  ft = "lua",
  cmd = "LazyDev",
  config = function()
    require("lazydev").setup({
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "nvim-lspconfig", words = { "lspconfig.settings" } },
      },
    })
  end,
}
