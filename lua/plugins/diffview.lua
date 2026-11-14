-- diffview-plus：完整工作区 diff 与工作树概览（自增功能）。
-- 上游 diffview 已停更；此分支持续修 bug，并带 :DiffviewWorktreeOverview。
-- 文件面板与布局键位用插件默认值，不覆盖。
return {
  "https://github.com/dlyongemallo/diffview-plus.nvim",
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewToggle",
    "DiffviewFileHistory",
    "DiffviewWorktreeOverview",
    "DiffviewLog",
    "DiffviewToggleFiles",
    "DiffviewFocusFiles",
    "DiffviewRefresh",
  },
  keys = {
    { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview (Working Tree)" },
    { "<leader>gV", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview File History" },
    { "<leader>gT", "<cmd>DiffviewToggle<cr>", desc = "Diffview Toggle" },
    { "<leader>gw", "<cmd>DiffviewWorktreeOverview<cr>", desc = "Worktree Overview" },
    { "<leader>gO", "<cmd>DiffviewLog<cr>", desc = "Diffview Log" },
  },
  opts = {},
}
