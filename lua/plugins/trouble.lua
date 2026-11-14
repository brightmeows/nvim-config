-- trouble：诊断列表。行为源：LazyVim plugins/editor.lua 的 trouble spec
-- （cmd + keys 字段；[q/]q 与 keymaps.lua 的 quickfix 键冲突——基线真值为
-- trouble 版本，经 keys 字段注册于 keymaps.lua 之前由 VeryLazy 后注册者胜）。
return {
  "https://github.com/folke/trouble.nvim",
  cmd = { "Trouble" },
  -- stylua: ignore
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
    -- <leader>cs 让位给 outline.nvim（自增功能）；trouble symbols 仍可用 :Trouble symbols
    { "<leader>cT", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols (Trouble)" },
    { "<leader>cS", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references/definitions/... (Trouble)" },
    { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
    { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    {
      "[q",
      function()
        if require("trouble").is_open() then
          require("trouble").prev({ skip_groups = true, jump = true })
        else
          local ok, err = pcall(vim.cmd.cprev)
          if not ok then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end
      end,
      desc = "Previous Trouble/Quickfix Item",
    },
    {
      "]q",
      function()
        if require("trouble").is_open() then
          require("trouble").next({ skip_groups = true, jump = true })
        else
          local ok, err = pcall(vim.cmd.cnext)
          if not ok then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end
      end,
      desc = "Next Trouble/Quickfix Item",
    },
  },
  config = function()
    require("trouble").setup({
      modes = {
        lsp = {
          win = { position = "right" },
        },
      },
    })
  end,
}
