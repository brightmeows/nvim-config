-- todo-comments：TODO 注释跳转与列表。行为源：LazyVim plugins/editor.lua 的
-- todo-comments spec（cmd + event=LazyFile + keys 字段；<leader>st/sT 的
-- 基线真值为 snacks_picker extra 版本，见 snacks.lua keys，此处不重复）。
return {
  "https://github.com/folke/todo-comments.nvim",
  cmd = { "TodoTrouble", "TodoTelescope" },
  event = "LazyFile",
  -- stylua: ignore
  keys = {
    { "]t", function() require("todo-comments").jump_next() end, desc = "Next Todo Comment" },
    { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous Todo Comment" },
    { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },
    { "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
  },
  config = function()
    require("todo-comments").setup({})
  end,
}
