-- bufferline：标签栏。行为源：LazyVim plugins/ui.lua 的 bufferline spec。
-- 差异：LazyVim 的 config 修复函数（会话恢复时刷新）保留；图标走 meow.icons。
return {
  src = "https://github.com/akinsho/bufferline.nvim",
  name = "bufferline.nvim",
  config = function()
    local icons = require("meow").icons
    require("bufferline").setup({
      options = {
        close_command = function(n)
          Snacks.bufdelete(n)
        end,
        right_mouse_command = function(n)
          Snacks.bufdelete(n)
        end,
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        diagnostics_indicator = function(_, _, diag)
          local ret = (diag.error and icons.diagnostics.Error .. diag.error .. " " or "")
            .. (diag.warning and icons.diagnostics.Warn .. diag.warning or "")
          return vim.trim(ret)
        end,
        offsets = {
          { filetype = "neo-tree", text = "Neo-tree", highlight = "Directory", text_align = "left" },
          { filetype = "snacks_layout_box" },
        },
        ---@param opts bufferline.IconFetcherOpts
        get_element_icon = function(opts)
          return icons.ft[opts.filetype]
        end,
      },
    })
    -- Fix bufferline when restoring a session（LazyVim 同款）
    vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
      callback = function()
        vim.schedule(function()
          pcall(nvim_bufferline)
        end)
      end,
    })

    -- LazyVim ui.lua 的 bufferline keymaps
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
    end
    map("<leader>bp", "<Cmd>BufferLineTogglePin<CR>", "Toggle Pin")
    map("<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", "Delete Non-Pinned Buffers")
    map("<leader>br", "<Cmd>BufferLineCloseRight<CR>", "Delete Buffers to the Right")
    map("<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", "Delete Buffers to the Left")
    map("<S-h>", "<cmd>BufferLineCyclePrev<cr>", "Prev Buffer")
    map("<S-l>", "<cmd>BufferLineCycleNext<cr>", "Next Buffer")
    map("[b", "<cmd>BufferLineCyclePrev<cr>", "Prev Buffer")
    map("]b", "<cmd>BufferLineCycleNext<cr>", "Next Buffer")
    map("[B", "<cmd>BufferLineMovePrev<cr>", "Move buffer prev")
    map("]B", "<cmd>BufferLineMoveNext<cr>", "Move buffer next")
    map("<leader>bj", "<cmd>BufferLinePick<cr>", "Pick Buffer")
  end,
}
