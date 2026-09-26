-- flash：跳转。行为源：LazyVim plugins/editor.lua 的 flash spec。
return {
  src = "https://github.com/folke/flash.nvim",
  name = "flash.nvim",
  config = function()
    require("flash").setup({})
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
    end
    map({ "n", "x", "o" }, "s", function()
      require("flash").jump()
    end, "Flash")
    map({ "n", "o", "x" }, "S", function()
      require("flash").treesitter()
    end, "Flash Treesitter")
    map("o", "r", function()
      require("flash").remote()
    end, "Remote Flash")
    map({ "o", "x" }, "R", function()
      require("flash").treesitter_search()
    end, "Treesitter Search")
    map("c", "<c-s>", function()
      require("flash").toggle()
    end, "Toggle Flash Search")
    map({ "n", "o", "x" }, "<c-space>", function()
      require("flash").treesitter({ actions = { ["<c-space>"] = "next", ["<BS>"] = "prev" } })
    end, "Treesitter Incremental Selection")
  end,
}
