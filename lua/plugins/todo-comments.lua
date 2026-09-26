-- todo-comments：TODO 注释跳转与列表。行为源：LazyVim plugins/editor.lua 的 todo-comments spec。
-- 差异：<leader>st/sT 的基线真值为 snacks_picker extra 版本（Snacks.picker.todo_comments），
-- 见 snacks-picker.lua；此文件只注册 ]t/[t 与 Trouble 列表键。
return {
  src = "https://github.com/folke/todo-comments.nvim",
  name = "todo-comments.nvim",
  config = function()
    require("todo-comments").setup({})
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
    end
    -- stylua: ignore
    map("]t", function() require("todo-comments").jump_next() end, "Next Todo Comment")
    -- stylua: ignore
    map("[t", function() require("todo-comments").jump_prev() end, "Previous Todo Comment")
    -- stylua: ignore
    map("<leader>xt", "<cmd>Trouble todo toggle<cr>", "Todo (Trouble)")
    -- stylua: ignore
    map("<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", "Todo/Fix/Fixme (Trouble)")
  end,
}
