-- persistence：会话管理。行为源：LazyVim plugins/util.lua 的 persistence spec。
return {
  src = "https://github.com/folke/persistence.nvim",
  name = "persistence.nvim",
  config = function()
    require("persistence").setup({})
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
    end
    map("<leader>qs", function()
      require("persistence").load()
    end, "Restore Session")
    map("<leader>qS", function()
      require("persistence").select()
    end, "Select Session")
    map("<leader>ql", function()
      require("persistence").load({ last = true })
    end, "Restore Last Session")
    map("<leader>qd", function()
      require("persistence").stop()
    end, "Don't Save Current Session")
  end,
}
