-- trouble：诊断列表。行为源：LazyVim plugins/editor.lua 的 trouble spec。
return {
  src = "https://github.com/folke/trouble.nvim",
  name = "trouble.nvim",
  config = function()
    require("trouble").setup({
      modes = {
        lsp = {
          win = { position = "right" },
        },
      },
    })
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
    end
    -- stylua: ignore
    map("<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", "Diagnostics (Trouble)")
    -- stylua: ignore
    map("<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Buffer Diagnostics (Trouble)")
    -- stylua: ignore
    map("<leader>cs", "<cmd>Trouble symbols toggle<cr>", "Symbols (Trouble)")
    -- stylua: ignore
    map("<leader>cS", "<cmd>Trouble lsp toggle<cr>", "LSP references/definitions/... (Trouble)")
    -- stylua: ignore
    map("<leader>xL", "<cmd>Trouble loclist toggle<cr>", "Location List (Trouble)")
    -- stylua: ignore
    map("<leader>xQ", "<cmd>Trouble qflist toggle<cr>", "Quickfix List (Trouble)")
    -- [q/]q 与 keymaps.lua 的 quickfix 键冲突——基线真值为 trouble 版本（后注册者胜）
    -- stylua: ignore
    map("[q", function()
      if require("trouble").is_open() then
        require("trouble").prev({ skip_groups = true, jump = true })
      else
        local ok, err = pcall(vim.cmd.cprev)
        if not ok then
          vim.notify(err, vim.log.levels.ERROR)
        end
      end
    end, "Previous Trouble/Quickfix Item")
    -- stylua: ignore
    map("]q", function()
      if require("trouble").is_open() then
        require("trouble").next({ skip_groups = true, jump = true })
      else
        local ok, err = pcall(vim.cmd.cnext)
        if not ok then
          vim.notify(err, vim.log.levels.ERROR)
        end
      end
    end, "Next Trouble/Quickfix Item")
  end,
}
